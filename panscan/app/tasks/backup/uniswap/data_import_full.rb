__TASK_NAME__ = "uniswap/data_import_full"

load(Task.load("base/auto-retry"))
load(Task.load("base/auto_split"))
load(Task.load("base/database"))
load(Task.load("base/data_store"))

def calc_swap_log(logs)
    return if logs["event_name"]!="Swap"

    amount0 = logs["args"]["amount0"]
    amount1 = logs["args"]["amount1"]
    return {tick:logs["args"]["tick"],amount0: amount0<0 ? 0 : amount0 ,amount1: amount1<0 ? 0 : amount1}
end

def calc_swap(block)
    data= block["data"]["logs"].map {|x| calc_swap_log(x) }
    return {} if data==[]
    {id:block["id"],block_number:block["block_number"],tick:data[-1][:tick], volume0:data.map {|x| x[:amount0]}.sum,volume1:data.map {|x| x[:amount1]}.sum }
end

class Pool
   attr_accessor :init_tick, :pool

    def initialize()
        self.pool = []
        self.init_tick = nil
    end
end


def calc_pool_log(logs,pool,id,block_number)
    if logs["event_name"]=="Initialize" then
        pool.init_tick = logs["args"]["tick"]
        return 
    end

    if logs["event_name"]=="IncreaseLiquidity" then
        pool.pool.push ({:id=>id,
                         :pool_id => logs["args"]["tokenId"],
                         :block_number=>block_number,
                         :amount0=>logs["args"]["amount0"],
                         :amount1=>logs["args"]["amount1"],
                         :liquidity=>logs["args"]["liquidity"]})
    end
    if logs["event_name"]=="DecreaseLiquidity" then
        pool.pool.push ({:id=>id,
                         :pool_id => logs["args"]["tokenId"],
                         :block_number=>block_number,
                         :amount0=>-logs["args"]["amount0"],
                         :amount1=>-logs["args"]["amount1"],
                         :liquidity=>-logs["args"]["liquidity"]})
    end
end

def calc_pool(block,pool)
    data= block["data"]["logs"].map {|x| calc_pool_log(x,pool,block["id"],block["block_number"]) }
end


def main()
    database_init() # allow to write
    DataStore.init()
    
    begin_param = __begin_param__
    end_param = __end_param__
    
    all_pools = DataStore.get("all_pools")
    
    if begin_param<0 then
        remote_task = []
        
        $logger.call "#{Time.now.to_s(:db)} - uniswap import"
        split_task_params(0,all_pools.size-1,10) { |begin_param,end_param|
          task_name = "data-import-block #{begin_param} - #{end_param}"
          $logger.call "#{task_name}"
          
          concurrent_limit(remote_task) {
              remote_task << Task.run_remote(_task.name,{begin_param:begin_param,end_param:end_param})
          }
        }
        
        remote_task = Task.wait_until_done(remote_task)
        abort_list = remote_task.filter {|x| x.status!="close"}
        if abort_list.size!=0 then
            $logger.call abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")
            raise "remote task abort"
        end

        $task.next_schedule_at = Time.now+60*60
        
    else

(begin_param..end_param).each do |cp|
    cur_pool=all_pools[cp]
    $logger.call "#{begin_param}..#{end_param} - #{cp}/#{all_pools.size} #{cur_pool}"
    
    ## skip USDC/ETH
    next if cur_pool[:token0]=="USDC" and cur_pool[:token1]=="ETH"

    pool = cur_pool[:pool]
    endpoint = "https://uniswap.funji.club/api/v1/uni/txn/"

    data = []
    last_id = 1

    loop do
        $logger.call last_id
        url = endpoint+pool+"?page_size=2000&last_id="+last_id.to_s
        conn = Faraday.new( url: url )
        response = conn.get() do |req|
            req["Authorization"] = "Bearer ff691328bb4547dcb5517baa23ab75c6"
        end

        slice = JSON.parse(response.body)["data"]
        
        break if slice.size==0

        data = data + slice
        
        # last_id = slice[-1]["id"]
        last_id = last_id+1
    end

    data = data.map.with_index {|x,i| x["id"]=i; x }

    timetable = data.map {|x| [x["block_number"],x["data"]["subgraph"]["timestamp"],Time.at(x["data"]["subgraph"]["timestamp"]).to_s[0,16]] }
    
    swap_data = data.deep_dup
    swap_data = swap_data.map {|x| x['data']['logs'] = x['data']['logs'].filter {|y| ["Swap"].include?( y['event_name']) }; x["input"]=""; x["subgraph"]={}; x}
    swap_data = swap_data.map {|x| calc_swap(x) }.filter {|x| x.has_key?(:tick) }

    swap_data.push({block_number:-1})

    swap = []
    acc_volume0=0
    acc_volume1=0
    
    swap_data.each.with_index do |x,i|
        swap.push({
            :id=>swap_data[i][:id],
            :block_number=>swap_data[i][:block_number],
            :tick=>swap_data[i][:tick],
            :volume0=>swap_data[i][:volume0],
            :volume1=>swap_data[i][:volume1],
        })
    end

    # (0..(swap_data.size-2)).each do |i|
    #     if swap_data[i][:block_number]==swap_data[i+1][:block_number] then
    #         acc_volume0 += swap_data[i][:volume0]
    #         acc_volume1 += swap_data[i][:volume1]
    #     else
    #         swap.push({
    #             :id=>swap_data[i][:id],
    #             :block_number=>swap_data[i][:block_number],
    #             :tick=>swap_data[i][:tick],
    #             :volume0=>swap_data[i][:volume0]+acc_volume0,
    #             :volume1=>swap_data[i][:volume1]+acc_volume1,
    #         })
    #         acc_volume0 = 0 
    #         acc_volume1 = 0
    #     end
    # end


    pool = Pool.new

    pool_data = data.deep_dup
    pool_data = pool_data.map {|x| x['data']['logs'] = x['data']['logs'].filter {|y| ["Initialize","IncreaseLiquidity","DecreaseLiquidity"].include?( y['event_name']) }; x["input"]=""; x["subgraph"]={}; x}
    pool_data_process = pool_data.map {|x| ret=calc_pool(x,pool); }

    _log "${begin_param} - #{end_param}"


    DataStore.set("uniswap.full.#{cur_pool[:pool]}",cur_pool)
    DataStore.set("uniswap.full.#{cur_pool[:pool]}.pool",pool.pool)
    DataStore.set("uniswap.full.#{cur_pool[:pool]}.swap",swap)
    DataStore.set("uniswap.full.#{cur_pool[:pool]}.init_tick",pool.init_tick)
    DataStore.set("uniswap.full.#{cur_pool[:pool]}.time_table",timetable)

    $logger.call " uniswap.full.#{cur_pool[:pool]} - #{JSON.dump(cur_pool).size} "
    $logger.call " uniswap.full.#{cur_pool[:pool]}.pool - #{JSON.dump(pool.pool).size} "
    $logger.call " uniswap.full.#{cur_pool[:pool]}.swap - #{JSON.dump(swap).size} "
    $logger.call " uniswap.full.#{cur_pool[:pool]}.init_tick - #{JSON.dump(pool.init_tick).size} "
    $logger.call " uniswap.full.#{cur_pool[:pool]}.time_table - #{JSON.dump(timetable).size} "
    nil
end

        
    end
end

