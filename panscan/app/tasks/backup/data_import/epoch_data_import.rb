__TASK_NAME__ = "data_import/epoch_data_import"


require 'parallel'
require 'resolv-replace'

load(Task.load("base/database"))
load(Task.load("panbot/online/pancake_prediction"))
load(Task.load("base/auto-retry"))

Object.include AutoRetry

def data_import_epoch(epoch,contract)
  if Epoch.find_by_epoch(epoch)==nil
 
    current_round = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { contract.call.rounds(epoch) }
    startTimestamp = Time.at(current_round[1])
    lockTimestamp = Time.at(current_round[2])
    closeTimestamp = Time.at(current_round[3])
    lockPrice = current_round[4]/1e8.to_f
    closePrice = current_round[5]/1e8.to_f
    totalAmount = current_round[8]/1e18.to_f
    bullAmount = current_round[9]/1e18.to_f
    bearAmount = current_round[10]/1e18.to_f
    rewardBaseCalAmount = current_round[11]/1e18.to_f
    rewardAmount = current_round[12]/1e18.to_f
    bullPayout = totalAmount/bullAmount
    bearPayout = totalAmount/bearAmount    

    ar = Epoch.new()
    ar.epoch = epoch
    ar.start_timestamp = startTimestamp
    ar.lock_timestamp = lockTimestamp
    ar.close_timestamp = closeTimestamp
    ar.lock_price = lockPrice
    ar.close_price = closePrice
    ar.total_amount = totalAmount
    ar.bull_amount = bullAmount
    ar.bear_amount = bearAmount
    ar.reward_base_cal_amount = rewardBaseCalAmount
    ar.reward_amount = rewardAmount
    ar.bull_payout = bullPayout
    ar.bear_payout = bearPayout

    ar.save!
  end
end


def main()
    database_init(false) # allow to write
    
    pan_call = PancakePrediction.new
    
    # db_last_epoch = Epoch.order(:epoch).last.epoch
    # last_epoch = pan_call.contract.call.current_epoch
    
    # _log "last_epoch = #{last_epoch}\n"
    # _log "db_last_epoch = #{db_last_epoch}\n"
    # _log "epochs #{last_epoch-db_last_epoch}\n"

    # epoch_min = db_last_epoch + 1
    # epoch_max = last_epoch - 1
    epoch_min = __epoch_min__
    epoch_max = __epoch_max__
    
    rounds = Parallel.map((epoch_min..epoch_max).to_a,in_threads: 10) do |epoch|
      data_import_epoch(epoch,pan_call.contract)
    end
    
    nil
end
