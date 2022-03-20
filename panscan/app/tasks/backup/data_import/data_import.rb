__TASK_NAME__ = "data_import/data_import"

load(Task.load("base/auto-retry"))
load(Task.load("base/database"))
load(Task.load("panbot/online/pancake_prediction"))

Object.include AutoRetry

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

    pan_call = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { PancakePrediction.new }
    
    # loop do
        _log "#{Time.now.to_s(:db)} - start this run\n"

        import_status = nil
        last_epoch = nil
        db_last_epoch = nil
        last_block = nil
        db_last_block = nil
        db_last_transfer_block = nil
        
        import_status = Cache.get("import_status")
        if import_status == nil or import_status["status"]=="close" then
            db_last_transfer_block = Transfer.order(:block_number).last.block_number
            last_block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.client.eth_get_block_by_number("latest",false)["result"]["number"].to_i(16) } 
            
            db_last_block = Block.order(:block_number).last.block_number
            db_last_epoch = Epoch.order(:epoch).last.epoch
            last_epoch = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.contract.call.current_epoch }
            last_block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.client.eth_get_block_by_number("latest",false)["result"]["number"].to_i(16) } 
    
            import_status = {"status":"stage-0","last_epoch":last_epoch,"db_last_epoch":db_last_epoch,"last_block":last_block,"db_last_block":db_last_block,"db_last_transfer_block":db_last_transfer_block}
            Cache.set("import_status",import_status)
        else
            last_epoch=import_status["last_epoch"]
            db_last_epoch=import_status["db_last_epoch"]
            last_block=import_status["last_block"]
            db_last_block=import_status["db_last_block"]
            db_last_transfer_block=import_status["db_last_transfer_block"]
        end
    
        _log "last_epoch = #{last_epoch}\n"
        _log "db_last_epoch = #{db_last_epoch}\n"
        _log "-----------------------\n"
        _log "last_block = #{last_block}\n"
        _log "db_last_block = #{db_last_block}\n"
        _log "-----------------------\n"
        _log "db_last_transfer_block = #{db_last_transfer_block}\n"
        _log "db_last_block = #{db_last_block}\n"
        _log "-----------------------\n"
        _log "epochs #{last_epoch-db_last_epoch} - blocks #{last_block-db_last_block} - transfer #{last_block-db_last_transfer_block}\n"
    
    
        import_status = Cache.get("import_status")
        if import_status["status"] == "stage-0" then
    
            ## step1 - block_data_import
            remote_task = []
            
            _log "#{Time.now.to_s(:db)} - block_data_import\n"
            split_task_params(db_last_block,last_block,10000) { |begin_param,end_param|
              task_name = "data-import-block #{begin_param} - #{end_param}"
              _log "#{task_name}\n"
              
              concurrent_limit(remote_task) {
                  remote_task << Task.run_remote("data_import/block_data_import",{block_begin:begin_param,block_end:end_param})
              }
            }
    
            ## step2 - epoch_data_import
            _log "#{Time.now.to_s(:db)} - epoch_data_import\n"
            concurrent_limit(remote_task) {
              remote_task << Task.run_remote("data_import/epoch_data_import",{epoch_min:db_last_epoch+1,epoch_max:last_epoch-2})    
            }
        
            ## wait all task done
            remote_task = Task.wait_until_done(remote_task)
            abort_list = remote_task.filter {|x| x.status!="close"}
            if abort_list.size!=0 then
                _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
                raise "remote task abort"
            end
            import_status["status"] = "stage-1"
            Cache.set("import_status",import_status)
        end
        
        import_status = Cache.get("import_status")
        if import_status["status"] == "stage-1" then
            # ## step3 - calc epoch
    
            remote_task = []
             _log "#{Time.now.to_s(:db)} - epoch_data_calc\n"
            remote_task << Task.run_remote("data_import/epoch_data_calc")    
        
        
            remote_task = Task.wait_until_done(remote_task)
            abort_list = remote_task.filter {|x| x.status!="close"}
            if abort_list.size!=0 then
                _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
                raise "remote task abort"
            end
            import_status["status"] = "stage-2"
            Cache.set("import_status",import_status)
        end
        
    
        import_status = Cache.get("import_status")
        if import_status["status"] == "stage-2" then
            ## step4 - transfer data import
             _log "#{Time.now.to_s(:db)} - transfer data import\n"
    
            remote_task = []
            split_task_params(db_last_transfer_block,last_block,10000) { |begin_param,end_param|
              task_name = "data-import-transfer #{begin_param} - #{end_param}"
              _log "#{task_name}\n"
              
              concurrent_limit(remote_task,4) {
                  remote_task << Task.run_remote("data_import/transfer_data_import",{block_begin:begin_param,block_end:end_param})
              }
            }
    
        
        
            remote_task = Task.wait_until_done(remote_task)
            abort_list = remote_task.filter {|x| x.status!="close"}
            if abort_list.size!=0 then
                _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
                raise "remote task abort"
            end
            import_status["status"] = "stage-3"
            Cache.set("import_status",import_status)
        end
    
        import_status = Cache.get("import_status")
        if import_status["status"] == "stage-3" then
            _log "#{Time.now.to_s(:db)} - bot stats calc\n"
            
            remote_task = []

            concurrent_limit(remote_task) {
              remote_task << Task.run_remote("data_import/bot_stats_calc_diff",{})    
            }

            remote_task = Task.wait_until_done(remote_task)
            abort_list = remote_task.filter {|x| x.status!="close"}
            if abort_list.size!=0 then
                _log abort_list.map{|x| [x.id,x.status].join(" ")}.join("\n")+"\n"
                raise "remote task abort"
            end
            
            
            import_status["status"] = "stage-4"
            Cache.set("import_status",import_status)
        end
    
    
    
        import_status = Cache.get("import_status")
        if import_status["status"] == "stage-4" then
            _log "#{Time.now.to_s(:db)} - close this run, sleep for next run\n"
            import_status["status"] = "close"
            Cache.set("import_status",import_status)
        end
        
        # sleep(3600)
    # end

end

def schedule_at()
    Time.now+3600*24
end

