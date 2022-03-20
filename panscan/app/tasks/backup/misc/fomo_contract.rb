__TASK_NAME__ = "misc/fomo_contract"

#5905762-7979362
require 'parallel'
require 'resolv-replace'

load(Task.load("base/auto-retry"))

require 'ethereum.rb'
require 'eth'
require 'faraday'
require 'parallel'
require 'resolv-replace'
require 'erb'    

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

def auto_split_remote_task(begin_param,end_param,step,concurrent_limit=8)
    if begin_param==nil or end_param==nil or end_param-begin_param+1 > step+1 then
        remote_task = []
        
        split_task_params(begin_param,end_param,step) { |begin_param,end_param|
          task_name = "#{_task.name} - #{begin_param} - #{end_param}"
          _log "#{task_name}\n"
          
          abi = _task.abi

          concurrent_limit(remote_task,concurrent_limit) {
              remote_task << Task.run_remote(_task.name,{abi[0]=>begin_param,abi[1]=>end_param})
          }
        }
        remote_task = Task.wait_until_done(remote_task)
        abort_list = remote_task.filter {|x| x.status!="close"}
        if abort_list.size!=0 then
            _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
            raise "remote task abort"
        end
        
        remote_task.map {|x| x.raw_ret}
    else
        yield(begin_param,end_param)    
    end
end



def main()
    Object.include AutoRetry

    begin_block =  __begin_block__
    end_block =  __end_block__
    step_limit = 100_000

    # map stage
    fomo_contracts = auto_split_remote_task(begin_block,end_block,step_limit,20) do |begin_block,end_block|

        method_map = {"0x8f38f309"=>true,"0x98a0871d"=>true,"0xa65b37a1"=>true}
        $client = Ethereum::HttpClient.new("https://eth-mainnet.alchemyapi.io/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa")
    
        time = Time.now
        
        fomo_contracts = Parallel.map((begin_block..end_block), in_threads: 30) { |cur_block|
            _log "#{cur_block}\n" if cur_block % 10000 == 0
            tx = auto_retry(lambda {|x| puts(x.to_s)},12) { $client.eth_get_block_by_number(cur_block,true)["result"]["transactions"] }
            tx.filter {|x| method_map[x["input"][0,10]]}.map { |x| x["to"] }.uniq
        }.flatten.uniq
        
        _log "time - #{Time.now-time}s \n"
        
        fomo_contracts
    end
    
    # reduce stage
    fomo_contracts = fomo_contracts.flatten.uniq
end
