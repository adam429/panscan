__TASK_NAME__ = "panbot/simulation/panbot_simulation_payout"


load(Task.load("base/database"))
load(Task.load("panbot/simulation/panbot_simulation_runner"))
load(Task.load("panbot/panbot_stats"))
load(Task.load("panbot/bot/panbot_payout_bot"))


def run_simluation(min_amount,min_payout,bet_amount_factor,bet_amount_value,epoch_begin,epoch_end,bot_class)
    config = {:min_amount => min_amount, :min_payout=>min_payout, :bet_amount_factor=>bet_amount_factor, :bet_amount_value=>bet_amount_value, :epoch_begin=>epoch_begin, :epoch_end=>epoch_end}
    _log config.to_s+"\n"
    
    time = Time.now()

    config_json = JSON.dump(config)
    if false and bet_result = Cache.get(bot_class.name+config_json) then
        bet_result = bet_result.map {|x| x.map { |k,v| [k.to_sym,v]}.to_h }
    else
        runner = SimulationRunner.new(->(x) { _log(x) })
        runner.time_at_epoch(epoch_begin,epoch_end)
        
        bot = bot_class.new(runner,config)
        runner.run
        bet_result = bot.bet_result
        
        # _log (bot.logs.join("\n"))
        # _log (bot.bet_result)
        
        Cache.set(bot_class.name+config_json,bet_result) 
    end

    _log bet_result.map{|x| x.to_s }.join(",\n")+"\n"
    _log "time #{Time.now()-time} s\n"
    
    stats(bet_result,epoch_begin,epoch_end)
end


def main
    bot_class = PayoutBot

    database_init()
    

    min_amount = __min_amount__
    min_payout = __min_payout__
    bet_amount_factor = __bet_amount_factor__
    bet_amount_value = __bet_amount_value__
    epoch_begin = __epoch_begin__
    epoch_end = __epoch_end__


    run_simluation(min_amount,min_payout,bet_amount_factor,bet_amount_value,epoch_begin,epoch_end,bot_class)
end

def render_html()
'''<h1>output</h1>
<% @raw_ret.each do |k,v| %>
    <li><%= k %> = <%= v %></li>
<% end %>
'''
end