__TASK_NAME__ = "base/auto_split"

def split_task_params(begin_param,end_param,step) 
    loop do
      task_end_params = [(begin_param+step)/step*step,begin_param+step-1,end_param].min
      
      yield(begin_param,task_end_params)
      
      begin_param = [(begin_param+step)/step*step,begin_param+step-1].min+1
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



def main
end