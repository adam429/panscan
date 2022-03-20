__TASK_NAME__ = "panbot/simulation/panbot_simulation_matrix_v2"

def main()
    min_amount_start = __min_amount_start__ 
    min_amount_stop = __min_amount_stop__ 
    min_amount_step = __min_amount_step__ 
    min_payout_start = __min_payout_start__ 
    min_payout_stop = __min_payout_stop__ 
    min_payout_step = __min_payout_step__ 
    bet_amount_factor_start = __bet_amount_factor_start__
    bet_amount_factor_stop = __bet_amount_factor_stop__
    bet_amount_factor_step = __bet_amount_factor_step__
    bet_amount_value_start = __bet_amount_value_start__
    bet_amount_value_stop = __bet_amount_value_stop__
    bet_amount_value_step = __bet_amount_value_step__
    
    
    remote_task = []
    for min_amount in (min_amount_start..min_amount_stop).step(min_amount_step) do
      for min_payout in (min_payout_start..min_payout_stop).step(min_payout_step) do
        for bet_amount_factor in (bet_amount_factor_start..bet_amount_factor_stop).step(bet_amount_factor_step) do
          for bet_amount_value in (bet_amount_value_start..bet_amount_value_stop).step(bet_amount_value_step) do
            cur_min_payout = min_payout.round(1)
            cur_min_amount = min_amount.round(0)
            cur_bet_amount_factor = bet_amount_factor.round(2)
            cur_bet_amount_value = bet_amount_value.round(1)
            config = {}
            config = {:epoch_begin=>__epoch_begin__, :epoch_end=>__epoch_end__}
            config[:min_amount] = cur_min_amount
            config[:min_payout] = cur_min_payout
            config[:bet_amount_factor] = cur_bet_amount_factor
            config[:bet_amount_value] = cur_bet_amount_value
            
            _log config.to_s+"\n"
            
            remote_task << Task.run_remote("panbot/simulation/panbot_simulation_payout",config)
          end
        end
      end
    end
    remote_task = Task.wait_until_done(remote_task)
    remote_task.map {|x| x.id}
end
