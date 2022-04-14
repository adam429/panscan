__TASK_NAME__ = "panbot/simulation/panbot_simulation_segmentation_interactive_v4"


load(Task.load("base/database"))
load(Task.load("panbot/simulation/panbot_simulation_runner"))
load(Task.load("panbot/bot/panbot_payout_bot"))
load(Task.load("panbot/panbot_stats"))

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))


class Segmentation < MappingObject
    
    def load_from_db(epoch_begin,epoch_end)
        data = Epoch.where(" ? <= epoch and epoch <= ? ",epoch_begin,epoch_end).map do |epoch|
            block = epoch.lock_block_number-3
            
            ob_bull_payout = 0
            ob_bear_payout = 0
            ob_bull_amount = epoch.get_bull_amount(block)
            ob_bear_amount = epoch.get_bear_amount(block)

            round_bull_payout = 0
            round_bear_payout = 0
            round_bull_amount = epoch.get_bull_amount(epoch.lock_block_number)
            round_bear_amount = epoch.get_bear_amount(epoch.lock_block_number)
            
            ob_total_amount = ob_bull_amount + ob_bear_amount
            if ob_bull_amount == 0 or ob_bear_amount == 0 then
                ob_bull_payout = 0
                ob_bear_payout = 0
            else
                ob_bull_payout =  ob_total_amount / ob_bull_amount
                ob_bear_payout=  ob_total_amount / ob_bear_amount
            end
            round_total_amount = round_bull_amount + round_bear_amount
            if round_bull_amount == 0 or round_bear_amount==0 then
                round_bull_payout = 0
                round_bear_payout = 0
            else
                round_bull_payout =  round_total_amount / round_bull_amount
                round_bear_payout=  round_total_amount / round_bear_amount
            end

            
            { 
                epoch:epoch.epoch,
                lock_price:epoch.lock_price,
                close_price:epoch.close_price,
                ob_bull_payout:ob_bull_payout, 
                ob_bear_payout:ob_bear_payout, 
                ob_bull_amount:ob_bull_amount, 
                ob_bear_amount:ob_bear_amount, 
                ob_payout:[ob_bull_payout,ob_bear_payout].max, 
                ob_amount:ob_total_amount,
                round_bull_payout:round_bull_payout, 
                round_bear_payout:round_bear_payout, 
                round_bull_amount:round_bull_amount, 
                round_bear_amount:round_bear_amount, 
                round_payout:[round_bull_payout,round_bear_payout].max, 
                round_amount:round_total_amount,
            }
        end
        self.data[:precalc] = data
    end
    
    def calc(epoch_begin,epoch_end,begin_payout,end_payout,begin_amount,end_amount,bet_amount)
        
        # segmentation
        epoch_begin = epoch_begin.to_i
        epoch_end = epoch_end.to_i
        begin_payout = begin_payout.to_f
        end_payout = end_payout.to_f
        begin_amount = begin_amount.to_f
        end_amount = end_amount.to_f
        
        filter = self.data[:precalc].filter {|x|
          begin_payout <= x[:ob_payout] and x[:ob_payout] <= end_payout and 
          begin_amount <= x[:ob_amount] and x[:ob_amount] <= end_amount and
          epoch_begin <= x[:epoch] and x[:epoch] <= epoch_end
        }

        count = filter.count
        ob_avg_payout = filter.map {|x| x[:ob_payout]}.sum.to_f / count
        ob_avg_amount = filter.map {|x| x[:ob_amount]}.sum.to_f / count
        ob_payout_arr = filter.map {|x| x[:ob_payout]}
        ob_amount_arr = filter.map {|x| x[:ob_amount]}

        round_avg_payout = filter.map {|x| x[:round_payout]}.sum.to_f / count
        round_avg_amount = filter.map {|x| x[:round_amount]}.sum.to_f / count
        round_payout_arr = filter.map {|x| x[:round_payout]}
        round_amount_arr = filter.map {|x| x[:round_amount]}
        
        # simulation
        filter = filter.map { |x|
            bet = x[:ob_bull_amount] < x[:ob_bear_amount] ? "bull" : "bear"
            right_bet = x[:round_bull_amount] < x[:round_bear_amount] ? "bull" : "bear"

            x[:bet] = bet
            x[:bet_bull_amount] = x[:round_bull_amount]
            x[:bet_bear_amount] = x[:round_bear_amount]

            if bet=="bull" then
                x[:bet_bull_amount] = x[:bet_bull_amount] + bet_amount
            end
            
            if bet=="bear" then
                x[:bet_bear_amount] = x[:bet_bear_amount] + bet_amount
            end

            bet_total_amount = x[:bet_bear_amount] + x[:bet_bull_amount]
            
            bet_bull_payout = 0
            bet_bear_payout = 0
            bet_bull_payout =  bet_total_amount / x[:bet_bull_amount] if x[:bet_bull_amount]!=0
            bet_bear_payout =  bet_total_amount / x[:bet_bear_amount] if x[:bet_bear_amount]!=0
            x[:bet_total_amount] = bet_total_amount
            x[:bet_bull_payout] = bet_bull_payout
            x[:bet_bear_payout] = bet_bear_payout
            
            win_bet = "bull" if x[:close_price] > x[:lock_price] 
            win_bet = "bear" if x[:close_price] < x[:lock_price] 
            win_bet = "draw" if x[:close_price] == x[:lock_price] 
            x[:win_bet] = win_bet

            ret_amount = -bet_amount
            
            if bet==win_bet then
                ret_amount = ret_amount +  bet_total_amount * 0.97 / x["bet_#{bet}_amount".to_sym] * bet_amount
            end                
            x[:ret_amount]=ret_amount
            bet=="bull" ? x[:bet_bull_ratio]=1 : x[:bet_bull_ratio]=0
            bet==win_bet ? x[:win_bet_ratio]=1 : x[:win_bet_ratio]=0
            (bet==right_bet and x["bet_#{bet}_payout".to_sym]>(2/0.97) ) ? x[:right_bet_ratio]=1 : x[:right_bet_ratio]=0

            if bet==win_bet then
                x[:bet_payout_win]=x["bet_#{bet}_payout".to_sym]
                x[:bet_payout_lose] = nil
            else
                x[:bet_payout_win]=nil
                x[:bet_payout_lose]=x["bet_#{bet}_payout".to_sym]
            end                
            x
        }

        arr = filter.filter {|x| x[:bet_payout_win]!=nil }.map {|x| x[:bet_payout_win]}
        bet_avg_payout_win = arr.sum.to_f / arr.count

        arr = filter.filter {|x| x[:bet_payout_lose]!=nil }.map {|x| x[:bet_payout_lose]}
        bet_avg_payout_lose = arr.sum.to_f / arr.count


        ret_amount = filter.map {|x| x[:ret_amount]}.sum
        bet_bull_ratio = filter.map {|x| x[:bet_bull_ratio]}.sum.to_f / count
        right_bet_ratio = filter.map {|x| x[:right_bet_ratio]}.sum.to_f / count
        win_bet_ratio = filter.map {|x| x[:win_bet_ratio]}.sum.to_f / count
        max_trace = 0
        
        running_return = 0
        filter.each do |x|
            running_return = running_return + x[:ret_amount]
            max_trace = running_return if running_return < max_trace
        end
        
        
        ret = { 
          count:count, 
          ob_avg_payout:ob_avg_payout, 
          ob_avg_amount:ob_avg_payout, 
          ob_payout_arr:ob_payout_arr,
          ob_amount_arr:ob_amount_arr,
          round_avg_payout:round_avg_payout, 
          round_avg_amount:round_avg_amount,
          round_payout_arr:round_payout_arr,
          round_amount_arr:round_amount_arr,
          ret_amount:ret_amount,
          bet_bull_ratio:bet_bull_ratio,
          right_bet_ratio:right_bet_ratio,
          win_bet_ratio:win_bet_ratio,
          max_trace:max_trace,
          bet_avg_payout_win:bet_avg_payout_win, 
          bet_avg_payout_lose:bet_avg_payout_lose, 
        }
        ret
    end
end

def main
    database_init()

    RenderWrap.load(Task.load("base/widget::pie_chart"))
    RenderWrap.load(Task.load("base/widget::bar_chart"))
    RenderWrap.load(Task.load("base/widget::dist_chart"))
    
    epoch_begin = __epoch_begin__
    epoch_end = __epoch_end__
    
    seg = Segmentation.new()
    seg.load_from_db(epoch_begin,epoch_end)

    RenderWrap.html = <<~EOS
    
<style>
#container {
  display: flex;                  /* establish flex container */
  flex-direction: row;            /* default value; can be omitted */
  flex-wrap: nowrap;              /* default value; can be omitted */
  justify-content: space-between; /* switched from default (flex-start, see below) */
}
#container > div {
  width: 400px;
}
</style>

<h1>Panbot Simulation Segmentation Interactive</h1>

<h3>==Params==</h3>
<div id="container">
    <div>
        epoch_begin: <%= text binding: :epoch_begin %>
        <%= slider min:data[:epoch_begin], max:data[:epoch_end], value:data[:epoch_begin], binding: :epoch_begin %> 
        
        epoch_end: <%= text binding: :epoch_end %>
        <%= slider min:data[:epoch_begin], max:data[:epoch_end], value:data[:epoch_end], binding: :epoch_end %> 
    </div>
    <div>
        <li><%= button text:"2021-Sep", action:":epoch_begin=1536; :epoch_end=9463" %> - [1536,9463]</li>
        <li><%= button text:"2021-Oct", action:":epoch_begin=9464; :epoch_end=16809" %> - [9464,16809]</li>
        <li><%= button text:"2021-Nov", action:":epoch_begin=16810; :epoch_end=24379" %> - [16810,24379]</li>
        <li><%= button text:"2021-Dec", action:":epoch_begin=24380; :epoch_end=32629" %> - [24380,32629]</li>
        <li><%= button text:"2022-Jan", action:":epoch_begin=32630; :epoch_end=41292" %> - [32630,41292]</li>
        <li><%= button text:"2022-Feb", action:":epoch_begin=41293; :epoch_end=49057" %> - [41293,49057]</li>
        <li><%= button text:"2022-Mar", action:":epoch_begin=49058; :epoch_end=57731" %> - [49058,57731]</li>
    </div>
    <div>
        min_payout: <%= text binding: :min_payout %>
        <%= calculated_var ":min_payout = :min_payout_raw.to_f/10" %>
        <%= slider min:20, max:100, value:24, binding: :min_payout_raw %> 
        
        max_payout: <%= text binding: :max_payout %>
        <%= calculated_var ":max_payout = :max_payout_raw.to_f/10" %>
        <%= slider min:20, max:100, value:25, binding: :max_payout_raw %> 

        <%= button text:"all range", action:":min_payout_raw=20; :max_payout_raw=100" %>
    </div>
    <div>
        min_amount: <%= text binding: :min_amount %>
        <%= slider min:0, max:50, value:20, binding: :min_amount %> 
        
        max_amount: <%= text binding: :max_amount %>
        <%= slider min:0, max:50, value:21, binding: :max_amount %> 

        <%= button text:"all range", action:":min_amount=0; :max_amount=50" %>
    </div>
</div>

<br/>
<br/>
<br/>
<div id="container">
    <div style="width:600px">
        <h3>==Segmentation==</h3>
        total epoch = <span style="color:red"><%= text binding: :total %></span> | segmentation epoch =  <%= text binding: :count %> | bet_ratio = <span style="color:red"> <%= text binding: :bet_ratio %> </span> <br/>
        <%= chart binding: :seg_portion_chart %> <br/>
        
        <% if false %>
        <%= chart binding: :dist_chart1 %><%= chart binding: :dist_chart2 %> <%= chart binding: :dist_chart3 %><%= chart binding: :dist_chart4 %>
        <% end %>
        
        ob avg payout (<%= text binding: :ob_avg_payout %>) -> round avg payout (<%= text binding: :round_avg_payout %>) <br/>
        ob avg amount (<%= text binding: :ob_avg_amount %>) -> round avg amount (<%= text binding: :round_avg_amount %>) <br/>
        
    </div>
    <div style="width:1000px">
        <h3>==Simulation Metrics==</h3>
        bet_amount: <span style="color:red"> <%= text binding: :bet_amount %> </span>
        <%= calculated_var ":bet_amount = :bet_amount_raw.to_f/10" %>
        <%= slider min:0, max:20, value:1, binding: :bet_amount_raw %> 
        
        
        [bet_avg_payout|win]= <span style="color:red"><%=text binding: :bet_avg_payout_win %></span>
        [bet_avg_payout|lose]=<%= text binding: :bet_avg_payout_lose  %> <br/><br/>
        
        <table>
          <tr><td>group</td><td>|</td><td>bet_bull_ratio</td><td>|</td><td>right_bet_ratio</td><td>|</td><td>payout|win</td><td>|</td><td>win_bet_ratio</td><td>|</td><td>max_trace</td><td>|</td><td>return_amt</td></tr>
          <tr><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>----</td></tr>
          <tr>
            <td>all</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio %></td>
            <td> | </td>
            <td><span style="color:red"><%= text binding: :bet_avg_payout_win %></span></td>
            <td> | </td>
            <td><span style="color:red"><%= text binding: :win_bet_ratio %></span></td>
            <td> | </td>
            <td><%= text binding: :max_trace %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount %></td>
          </tr>
          <tr><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>|</td><td>----</td><td>----</td></tr>
          <tr>
            <td>2021-9</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m9 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m9 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m9 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m9 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m9 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m9 %></td>
          </tr>    
          <tr>
            <td>2021-10</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m10 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m10 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m10 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m10 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m10 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m10 %></td>
          </tr>          
          <tr>
            <td>2021-11</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m11 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m11 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m11 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m11 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m11 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m11 %></td>
          </tr>          
          <tr>
            <td>2021-12</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m12 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m12 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m12 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m12 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m12 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m12 %></td>
          </tr>          
          <tr>
            <td>2022-01</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m1 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m1 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m1 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m1 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m1 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m1 %></td>
          </tr>
          <tr>
            <td>2022-02</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m2 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m2 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m2 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m2 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m2 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m2 %></td>
          </tr>
          <tr>
            <td>2022-03</td>
            <td> | </td>
            <td><%= text binding: :bet_bull_ratio_m3 %></td>
            <td> | </td>
            <td><%= text binding: :right_bet_ratio_m3 %></td>
            <td> | </td>
            <td><%= text binding: :bet_avg_payout_win_m3 %></td>
            <td> | </td>
            <td><%= text binding: :win_bet_ratio_m3 %></td>
            <td> | </td>
            <td><%= text binding: :max_trace_m3 %></td>
            <td> | </td>
            <td><%= text binding: :ret_amount_m3 %></td>
          </tr>
        </table>
    </div>
</div>

<br/>
<br/>
<br/>

<h3>==Calculation==</h3>

<table>
<tr>
    <td>Return Amount </td>
    <td>= </td>
    <td>Total Epoch </td>
    <td>*</td>
    <td>Bet Ratio</td>
    <td>* </td>
    <td>Bet Amount</td>
    <td>* ( </td>
    <td>Round_Payout|Win </td>
    <td>* </td>
    <td>Win Bet Ratio </td>
    <td>* 0.97 - 1 )</td>
</tr>
<tr>
    <td><span style="color:red"><%= text binding: :ret_amount %></span> </td>
    <td>= </td>
    <td><span style="color:red"><%= text binding: :total %></span> </td>
    <td>* </td>
    <td><span style="color:red"><%= text binding: :bet_ratio %></span> </td>
    <td>* </td>
    <td><span style="color:red"><%= text binding: :bet_amount %></span> </td>
    <td>* ( </td>
    <td><span style="color:red"><%= text binding: :bet_avg_payout_win %></span> </td>
    <td>* </td>
    <td><span style="color:red"><%= text binding: :win_bet_ratio %></span></td>
    <td>* 0.97 - 1 )</td>
</tr>
</table>

<% calculated_var ":calc = $data['seg'.to_sym].calc(:epoch_begin,:epoch_end,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":count = :calc['count'.to_sym]" %>
<% calculated_var ":ob_avg_payout = :calc['ob_avg_payout'].round(2)" %>
<% calculated_var ":ob_avg_amount = :calc['ob_avg_amount'].round(2)" %>
<% calculated_var ":ob_payout_arr = :calc['ob_payout_arr']" %>
<% calculated_var ":ob_amount_arr = :calc['ob_amount_arr']" %>
<% calculated_var ":round_avg_payout = :calc['round_avg_payout'].round(2)" %>
<% calculated_var ":bet_avg_payout_win = :calc['bet_avg_payout_win'].round(4)" %>
<% calculated_var ":bet_avg_payout_lose = :calc['bet_avg_payout_lose'].round(4)" %>
<% calculated_var ":round_avg_amount = :calc['round_avg_amount'].round(2)" %>
<% calculated_var ":round_payout_arr = :calc['round_payout_arr']" %>
<% calculated_var ":round_amount_arr = :calc['round_amount_arr']" %>
<% calculated_var ":ret_amount = :calc['ret_amount'].round(4)" %>
<% calculated_var ":max_trace = :calc['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio = :calc['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio = :calc['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio = :calc['bet_bull_ratio'].round(4)" %>
<% calculated_var ":total = :epoch_end.to_i - :epoch_begin.to_i + 1 " %>

<% calculated_var ":bet_ratio = (:count / :total).round(4)" %>
<% calculated_var ':seg_portion_chart = pie_chart([{"category"=>"2-Other","value"=>:total-:count},{"category"=>"1-Segmentation","value"=>:count}],"Segmentation Portion")' %>
<% calculated_var ':dist_chart1 = dist_chart(:ob_payout_arr.map{|x| {"vals"=>x} },"ob payout")' %>
<% calculated_var ':dist_chart2 = dist_chart(:round_payout_arr.map{|x| {"vals"=>x} },"round payout")' %>
<% calculated_var ':dist_chart3 = dist_chart(:ob_amount_arr.map{|x| {"vals"=>x} },"ob amount")' %>
<% calculated_var ':dist_chart4 = dist_chart(:round_amount_arr.map{|x| {"vals"=>x} },"round amount")' %>

<% calculated_var ":calc_m9 = $data['seg'.to_sym].calc(1536,9463,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m9 = :calc_m9['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m9 = :calc_m9['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m9 = :calc_m9['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m9 = :calc_m9['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m9 = :calc_m9['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m9 = :calc_m9['bet_avg_payout_win'].round(4)" %>

<% calculated_var ":calc_m10 = $data['seg'.to_sym].calc(9464,16809,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m10 = :calc_m10['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m10 = :calc_m10['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m10 = :calc_m10['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m10 = :calc_m10['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m10 = :calc_m10['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m10 = :calc_m10['bet_avg_payout_win'].round(4)" %>

<% calculated_var ":calc_m11 = $data['seg'.to_sym].calc(16810,24379,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m11 = :calc_m11['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m11 = :calc_m11['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m11 = :calc_m11['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m11 = :calc_m11['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m11 = :calc_m11['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m11 = :calc_m11['bet_avg_payout_win'].round(4)" %>


<% calculated_var ":calc_m12 = $data['seg'.to_sym].calc(24380,32629,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m12 = :calc_m12['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m12 = :calc_m12['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m12 = :calc_m12['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m12 = :calc_m12['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m12 = :calc_m12['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m12 = :calc_m12['bet_avg_payout_win'].round(4)" %>

<% calculated_var ":calc_m1 = $data['seg'.to_sym].calc(32630,41292,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m1 = :calc_m1['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m1 = :calc_m1['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m1 = :calc_m1['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m1 = :calc_m1['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m1 = :calc_m1['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m1 = :calc_m1['bet_avg_payout_win'].round(4)" %>

<% calculated_var ":calc_m2 = $data['seg'.to_sym].calc(41293,49057,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m2 = :calc_m2['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m2 = :calc_m2['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m2 = :calc_m2['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m2 = :calc_m2['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m2 = :calc_m2['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m2 = :calc_m2['bet_avg_payout_win'].round(4)" %>

<% calculated_var ":calc_m3 = $data['seg'.to_sym].calc(49058,57731,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":ret_amount_m3 = :calc_m3['ret_amount'].round(4)" %>
<% calculated_var ":max_trace_m3 = :calc_m3['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio_m3 = :calc_m3['win_bet_ratio'].round(4)" %>
<% calculated_var ":right_bet_ratio_m3 = :calc_m3['right_bet_ratio'].round(4)" %>
<% calculated_var ":bet_bull_ratio_m3 = :calc_m3['bet_bull_ratio'].round(4)" %>
<% calculated_var ":bet_avg_payout_win_m3 = :calc_m3['bet_avg_payout_win'].round(4)" %>

EOS


RenderWrap.jsrb = <<~EOS
    puts "ready"
EOS

    RenderWrap[:epoch_begin] = epoch_begin
    RenderWrap[:epoch_end] = epoch_end
    RenderWrap[:seg] = seg
    RenderWrap.data
end

