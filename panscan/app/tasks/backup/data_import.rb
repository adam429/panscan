__TASK_NAME__ = "data_import"

load(Task.load("block_data_import"))
load(Task.load("auto-retry"))
Object.include AutoRetry

def split_task_params(begin_param,end_param,step) 
    loop do
      task_end_params = [(begin_param+step)/step*step,begin_param+step,end_param].min
      
      yield(begin_param,task_end_params)
      
      begin_param = [(begin_param+step)/step*step,begin_param+step].min
      break if begin_param > end_param
    end
end


def main()
    database_init(false) # allow to write

    pan_call = PancakePrediction.new


    db_last_transfer_block = Transfer.order(:block_number).last.block_number
    last_block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.client.eth_get_block_by_number("latest",false)["result"]["number"].to_i(16) } 
    
    db_last_block = Block.order(:block_number).last.block_number
    db_last_epoch = Epoch.order(:epoch).last.epoch
    last_epoch = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.contract.call.current_epoch }
    last_block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_call.client.eth_get_block_by_number("latest",false)["result"]["number"].to_i(16) } 
    
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

    remote_task = []
    remote_task2 = []


    ## step1 - block_data_import
    split_task_params(db_last_block,last_block,10000) { |begin_param,end_param|
      task_name = "data-import-block #{begin_param} - #{end_param}"
      _log "#{task_name}\n"
      remote_task << Task.run_remote("block_data_import",{block_begin:begin_param,block_end:end_param})
    }
    
     
    ## step2 - epoch_data_import
     _log "epoch_data_import\n"
    remote_task << Task.run_remote("epoch_data_import",{epoch_min:db_last_epoch+1,epoch_max:last_epoch-2})    

    ## wait all task done
    remote_task = Task.wait_until_done(remote_task)
    remote_task.map {|x| x.id}
    
    ## step3 - calc epoch
     _log "epoch_data_calc\n"

    remote_task2 << Task.run_remote("epoch_data_calc")    
    
    ## step4 - transfer data import
     _log "transfer data import\n"
    
    ## step5 - bot stats calc
     _log "bot stats calc\n"
    
    

end
