__TASK_NAME__ = "panbot/simulation/panbot_simulation_batch"

def main()
    bet_amount_factor = [0]
    bet_amount_value = [0.1]
    min_amount = [30]
    min_payout = [2.4, 2.7]
    epoch = [[32630,41292],[41293,49057],[49058,55387]]
    
    remote_task = []
    
    bet_amount_factor.each do |x0|
        bet_amount_value.each do |x1|
            min_amount.each do |x2|
                min_payout.each do |x3|
                    epoch.each do |range|
                        x4 = range[0]
                        x5 = range[1]
                        
                        config = {
                            :bet_amount_factor=>x0, 
                            :bet_amount_value=>x1, 
                            :min_amount=>x2,
                            :min_payout=>x3,
                            :epoch_begin=>x4, :epoch_end=>x5}
                        task = Task.run_remote("panbot/simulation/panbot_simulation_payout",config)
                        remote_task << task
                        _log "[task: #{task.id}} ] - #{config}\n"
                    end
                end
            end
        end
    end

    remote_task = Task.wait_until_done(remote_task)
    remote_task.map {|x| x.id}
end
