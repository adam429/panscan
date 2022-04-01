__TASK_NAME__ = "panbot/simulation/panbot_simulation_payout_metric_window"


load(Task.load("base/database"))
load(Task.load("panbot/simulation/panbot_simulation_runner"))
load(Task.load("panbot/bot/panbot_payout_bot"))

load(Task.load("base/render_wrap"))
load(Task.load("base/opal_binding"))
load(Task.load("base/widget"))

## load panbot_stats
load(Task.load("panbot/panbot_stats"))
RenderWrap.load(Task.load("panbot/panbot_stats"))

load(Task.load("base/logger"))


def run_simluation(min_amount,min_payout,bet_amount_factor,bet_amount_value,epoch_begin,epoch_end,bot_class)
    config = {:min_amount => min_amount, :min_payout=>min_payout, :bet_amount_factor=>bet_amount_factor, :bet_amount_value=>bet_amount_value, :epoch_begin=>epoch_begin, :epoch_end=>epoch_end}
    _log config.to_s+"\n"
    
    time = Time.now()


    config_json = JSON.dump(config)
    if bet_result = Cache.get(bot_class.name+config_json) then
        bet_result = bet_result.map {|x| x.map { |k,v| [k.to_sym,v]}.to_h }
    else
        runner = SimulationRunner.new(->(x) { _log(x) })
        runner.time_at_epoch(epoch_begin,epoch_end)
        
        bot = bot_class.new(runner,config)
        runner.run
        bet_result = bot.bet_result
        
        _log (bot.logs.join("\n"))
        _log (bot.bet_result)
        
        Cache.set(bot_class.name+config_json,bet_result) 
    end

    _log bet_result.join("\n")+"\n"
    _log "time #{Time.now()-time} s\n"
    
    {bet_result:bet_result,epoch_begin:epoch_begin,epoch_end:epoch_end}
end

def calc_window(bet_result,epoch_begin,epoch_end,window_size)
    windows = (epoch_begin..epoch_end-window_size+1).map {|x|
        stats(bet_result,x,x+window_size)
    }
    
    {
        bet_cnt:windows.map {|x| x["bet_cnt"]},
        bet_ratio:windows.map {|x| x["bet_ratio"]},
        bet_round_payout:windows.map {|x| x["bet_round_payout"]},
        bet_bull_ratio:windows.map {|x| x["bet_bull_ratio"]},
        right_bet_ratio:windows.map {|x| x["right_bet_ratio"]},
        win_bet_ratio:windows.map {|x| x["win_bet_ratio"]},
        return_amt:windows.map {|x| x["return_amt"]},
        max_retrace:windows.map {|x| x["max_retrace"]},
    }
end

def dist_chart(input,title)
{
  "title": title,
  "data": {"values": input.map {|x| {vals:x} }} ,
  "transform": [
    {"bin": {"maxbins": 30}, "field": "vals", "as": "vals_"},
    {"calculate": "round(datum.vals_*100)/100", "as": "vals_binned"}
  ],
  "width": 200,
  "height": 200,
  "layer": [
    {
      "params": [{
            "name": "brush",
            "select": {"type": "interval", "encodings": ["x"]}
          }],      
      "mark": "bar",
      "encoding": {
        "x": {"field": "vals_binned" },
        "y": {"aggregate": "count", "field": "vals_binned"},
        "tooltip": [
          {"field": "vals_binned"},
          {"field": "vals_binned)", "aggregate": "count"}
        ],
        "opacity": {
                "condition": {
                  "param": "brush", "value": 1
                },
                "value": 0.7
            }        
      }
    },
    {
      "transform": [
        {"filter": {"param": "brush"}},
      ],
      "mark": {
        "type": "text",
        "dx": {"expr": 80},
        "dy": {"expr": -80},        
      },
      "encoding": {
         "color": {"value": "firebrick"},
         "text": {"field": "vals_binned", "aggregate": "count"}
      }
    }    
  ]
}
    
end


def main
    init_logger(binding)
    RenderWrap.load(Task.load("#{_task.name}::calc_window"))
    RenderWrap.load(Task.load("#{_task.name}::dist_chart"))
    
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
    RenderWrap.html =  <<~EOS
<% 
  epoch_begin = @raw_ret[:epoch_begin]
  epoch_end = @raw_ret[:epoch_end]
%>
<%= var :bet_result, @raw_ret[:bet_result]%>

<h1>Panbot Simulation Payout Metric Dist</h1>

epoch_begin: <%= text binding: :epoch_begin %>
<%= slider min:epoch_begin, max:epoch_end, value:epoch_begin, binding: :epoch_begin %> 

epoch_end: <%= text binding: :epoch_end %>
<%= slider min:epoch_begin, max:epoch_end, value:epoch_end, binding: :epoch_end %> 

window_size: <%= text binding: :window_size %>
<%= slider min:1, max:1000, value:288 , binding: :window_size %> 

<%= chart binding: :bet_cnt %> 
<%= chart binding: :bet_ratio %> 
<%= chart binding: :bet_round_payout %> 
<%= chart binding: :bet_bull_ratio %><br/> 
<%= chart binding: :right_bet_ratio %> 
<%= chart binding: :win_bet_ratio %> 
<%= chart binding: :return_amt %> 
<%= chart binding: :max_retrace %> <br/>


<% calculated_var ":window = calc_window(:bet_result,:epoch_begin.to_i,:epoch_end.to_i,:window_size.to_i)" %>

<% calculated_var ":bet_cnt = ->(x){ dist_chart(x['bet_cnt'],'bet_cnt') }.call(:window)" %>
<% calculated_var ":bet_ratio = ->(x){ dist_chart(x['bet_ratio'],'bet_ratio') }.call(:window)" %>
<% calculated_var ":bet_round_payout = ->(x){ dist_chart(x['bet_round_payout'],'bet_round_payout') }.call(:window)" %>
<% calculated_var ":bet_bull_ratio = ->(x){ dist_chart(x['bet_bull_ratio'],'bet_bull_ratio') }.call(:window)" %>
<% calculated_var ":right_bet_ratio = ->(x){ dist_chart(x['right_bet_ratio'],'right_bet_ratio') }.call(:window)" %>
<% calculated_var ":win_bet_ratio = ->(x){ dist_chart(x['win_bet_ratio'],'win_bet_ratio') }.call(:window)" %>
<% calculated_var ":return_amt = ->(x){ dist_chart(x['return_amt'],'return_amt') }.call(:window)" %>
<% calculated_var ":max_retrace = ->(x){ dist_chart(x['max_retrace'],'max_retrace') }.call(:window)" %>

EOS
    RenderWrap.render_html(binding)

end

'''
bet_round_payout: <br/> <%= chart binding: :bet_round_payout %> <br/>
bet_bull_ratio: <br/> <%= chart binding: :bet_bull_ratio %> <br/>
right_bet_ratio:<br/> <%= chart binding: :right_bet_ratio %> <br/>
win_bet_ratio: <br/> <%= chart binding: :win_bet_ratio %> <br/>
return_amt: <br/> <%= chart binding: :return_amt %> <br/>
max_retrace: <br/> <%= chart binding: :max_retrace %> <br/>
'''

def render_js_rb()
    RenderWrap.jsrb = 
'''

'''
    RenderWrap.render_jsrb(binding)

end
