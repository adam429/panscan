__TASK_NAME__ = "panbot/online/panbot_auto_claim"


load(Task.load("base/database"))
load(Task.load("base/auto-retry"))
load(Task.load("panbot/online/pancake_prediction"))

Object.include AutoRetry

def main
    database_init()
    
    bots = Vault.get("bot_private_key")

    pan_actions = bots.map {|b|
        auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { PancakePrediction.new(1,b) }
    }
    
    # loop do
        pan_actions.each_with_index { |pan_action,i|
            _log "== Bot #{i} ==\n"
            balance = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_action.client.eth_get_balance(pan_action.bot_address)["result"].to_i(16) / 1e18.to_f }
            epoch = pan_action.contract.call.current_epoch
        
            _log "=== #{Time.now.to_s(:db)} - Bot Address: #{pan_action.bot_address} - #{balance} BNB ==\n"
            claimable = (epoch-1000..epoch).map {|x|
                claimable = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_action.contract.call.claimable(x,pan_action.bot_address) }
                [x,claimable]
            }.filter { |x| x[1] }.map {|x| x[0]}
            _log "=== #{claimable.count} - #{claimable.to_s} ===\n"
            pan_action.contract.transact_and_wait.claim(claimable) if claimable.size>0
    
            balance = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { pan_action.client.eth_get_balance(pan_action.bot_address)["result"].to_i(16) / 1e18.to_f }
            _log "=== #{Time.now.to_s(:db)} - Bot Address: #{pan_action.bot_address} - #{balance} BNB ==\n"
            
        }
        _log "=== close this run, sleep for next run ==\n"
    #     sleep(3600)
    # end    

    $task.next_schedule_at = Time.now+3600
end

