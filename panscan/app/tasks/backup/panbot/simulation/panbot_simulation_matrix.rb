__TASK_NAME__ = "panbot/simulation/panbot_simulation_matrix"

def main()
    min_amount_start = __min_amount_start__ 
    min_amount_stop = __min_amount_stop__ 
    min_amount_step = __min_amount_step__ 
    min_payout_start = __min_payout_start__ 
    min_payout_stop = __min_payout_stop__ 
    min_payout_step = __min_payout_step__ 
    
    remote_task = []
    for min_amount in (min_amount_start..min_amount_stop).step(min_amount_step) do
      for min_payout in (min_payout_start..min_payout_stop).step(min_payout_step) do
        cur_min_payout = min_payout.round(1)
        cur_min_amount = min_amount.round(0)
        config = {}
        config = {:bet_amount_factor=>__bet_amount_factor__, :bet_amount_value=>__bet_amount_value__, :epoch_begin=>__epoch_begin__, :epoch_end=>__epoch_end__}
        config[:min_amount] = cur_min_amount
        config[:min_payout] = cur_min_payout
        
        # _log config.to_s+"\n"

        remote_task << Task.run_remote("panbot/simulation/panbot_simulation_payout",config)
      end
    end
    remote_task = Task.wait_until_done(remote_task)
    remote_task.map {|x| x.id}
end
