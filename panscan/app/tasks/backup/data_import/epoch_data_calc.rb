__TASK_NAME__ = "data_import/epoch_data_calc"


require 'parallel'
require 'resolv-replace'

load(Task.load("base/database"))

def epoch_calc(epoch_start,epoch_end)
    
    time = Time.now
    
    Parallel.map((epoch_start..epoch_end).to_a,in_threads: 10) do |epoch_number|
      _log "time:#{Time.now} epoch_number: #{epoch_number}\n" if epoch_number%1000==0
    
      e = Epoch.find_by_epoch(epoch_number)
      $logger.call "epoch #{epoch_number} is missing" if e==nil
      next if not (e.total_count==nil or e.total_count==0)
    
      e.total_count = e._event.where("name = ? or name = ?","BetBear","BetBull").count
    
      start_block = e._block.where("? <= block_time and block_time < ?",e.start_timestamp,e.start_timestamp+30).order(:block_time).first
      e.start_block_number = start_block ? start_block.block_number : 0
    
      lock_block = e._block.where("? <= block_time and block_time < ?",e.lock_timestamp,e.lock_timestamp+30).order(:block_time).first
      e.lock_block_number = lock_block ? lock_block.block_number : 0
      e.save!
    
      # block belong to epoch
      local_epoch = Epoch.find_by_epoch(epoch_number)  
      local_block = local_epoch._block
      local_block.in_batches.update_all(epoch: local_epoch.epoch)
      nil
    end
    nil
    _log "epoch calc  #{ Time.now-time }\n"
        
end

def epoch_tx_calc(epoch_start,epoch_end)

    time = Time.now

    Parallel.map((epoch_start..epoch_end).to_a,in_threads: 10) do |epoch_number|
        _log "time:#{Time.now} epoch_number: #{epoch_number}\n" if epoch_number%1000==0
        local_epoch = Epoch.find_by_epoch(epoch_number)
        next if local_epoch.detail.size!=0
      
        event_map = {}
        local_epoch.event.each {|event|
            amount = JSON.parse(event.params)["amount"]
            if event.name=="BetBull" or event.name=="BetBear" then
              event_map[event.tx_hash] = [
                  event.name,
                  amount,
                  event.block_number
              ]
            end
        }            
        bull_amount = 0
        bear_amount = 0
        count =0
    
        local_epoch.block.each {|block|
            tx = event_map.to_a.map {|x| x.flatten}.filter {|x| x[3]==block.block_number}
            tx.each do |x|
              if x[1]=="BetBull" then
                  bull_amount=bull_amount+x[2]
              end
              if x[1]=="BetBear" then
                  bear_amount=bear_amount+x[2]
              end
            end
            count = count +tx.size
            
            ed = EpochDetail.new()
            ed.block_number = block.block_number
            ed.block_time = block.block_time
            ed.epoch = local_epoch.epoch
            ed.bet_count = count
            ed.bull_amount = bull_amount
            ed.bear_amount = bear_amount
            ed.bull_payout = bull_amount==0?0:(bull_amount+bear_amount)/bull_amount
            ed.bear_payout = bear_amount==0?0:(bull_amount+bear_amount)/bear_amount
            ed.save
                
        }            
    end
    _log "epoch_tx calc #{ Time.now-time }\n"
                      

end


def main()
    database_init(false) # allow to write
    
    epoch_start = Epoch.where("total_count is null or total_count = 0").select(:epoch).map {|x| x.epoch}.min
    epoch_end = Epoch.where("total_count is null or total_count = 0").select(:epoch).map {|x| x.epoch}.max

    if epoch_start==nil or epoch_end==nil then
        _log ("epoch data is updated\n")
    else
        _log ("epoch_calc - epoch_start #{epoch_start} - epoch_end #{epoch_end}\n")
    
        epoch_calc(epoch_start,epoch_end)
        epoch_tx_calc(epoch_start,epoch_end)
    end

end
