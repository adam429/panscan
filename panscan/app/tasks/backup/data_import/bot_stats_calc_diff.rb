__TASK_NAME__ = "data_import/bot_stats_calc_diff"


require 'parallel'
require 'resolv-replace'

load(Task.load("base/database"))
load(Task.load("base/auto-retry"))
load(Task.load("panbot/online/pancake_prediction"))

def split_task_params(begin_param,end_param,step) 
    loop do
      task_end_params = [(begin_param+step)/step*step,begin_param+step,end_param].min
      
      yield(begin_param,task_end_params)
      
      begin_param = [(begin_param+step)/step*step,begin_param+step].min
      break if begin_param > end_param
    end
end

def concurrent_limit(queue,limit=8)
    loop do
        queue_count = Task.where(id: queue.map {|x| x.id}).where("status='run' or status='open'").count
        if queue_count<limit then
            yield
            return
        end
        sleep 1 
    end
end


def main()
    database_init(false) # allow to write


    Object.include AutoRetry
    pan_call = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { PancakePrediction.new }

    get_abi = -> (contract_addr) {
      api_url = "https://api.bscscan.com/api?module=contract&action=getabi&address=#{contract_addr}&apikey=#{Vault.get("bscscan-apikey")}"
      abi = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { 
          ret = JSON.parse(response = Faraday.get(api_url).body)["result"] 
          if ret == "Max rate limit reached" then
              sleep 1
              raise JSON::ParserError
          end
          ret
      }
      return abi
    }
    
    Address.client = pan_call.client
    Address.get_abi = get_abi
    Address.decoder = Ethereum::Decoder.new
    

    all_address = Tx.select(:from).distinct.all.map {|x| x.from}
    addr_hash = all_address.map {|x| [x,true]}.to_h
    Address.panbot_address = addr_hash
    
    Cache.set("bot_stats_calc.panbot_address",addr_hash)

    import_status = Cache.get("import_status")
    
    begin_block = import_status["db_last_block"]
    end_block = import_status["last_block"]

    addr_list = Tx.where("? <= block_number and block_number <=?",begin_block,end_block).where("method_name=? or method_name=?",'betBear','betBull').select(:from).distinct(:from).map.with_index.map {|x,i| [x.from, 0, i] }
    
    _log "addr_list.count #{addr_list.count}\n"

    Cache.set("bot_stats_calc.addr_list",addr_list)
    
    remote_task = []
    start_addr = 0


    split_task_params(start_addr,addr_list.count-1,10) { |begin_param,end_param|
      task_name = "bot_stats_calc #{begin_param} - #{end_param}"
      _log "#{task_name}\n"
      
      concurrent_limit(remote_task) {
          remote_task << Task.run_remote("data_import/bot_stats_calc_item",{addr_begin:begin_param,addr_end:end_param})
      }
    }

    ## wait all task done
    remote_task = Task.wait_until_done(remote_task)
    abort_list = remote_task.filter {|x| x.status!="close"}
    if abort_list.size!=0 then
        _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
        raise "remote task abort"
    end

    
    nil
    
end
