__TASK_NAME__ = "panbot/simulation/panbot_simulation_segmentation_interactive"


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
        filter.map { |x|
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
            bet==right_bet ? x[:right_bet_ratio]=1 : x[:right_bet_ratio]=0
            
            x
        }

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
        
        
        { 
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
        }
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
        
        <li><%= button text:"2022-Jan", action:"put 'hello world!'" %> - [32630,41292]</li>
        <li><%= button text:"2022-Feb", action:"put 'hello world!'" %> - [41293,49057]</li>
        <li><%= button text:"2022-Mar", action:"put 'hello world!'" %> - [49058,57731]</li>
    </div>
    <div>
        min_payout: <%= text binding: :min_payout %>
        <%= calculated_var ":min_payout = :min_payout_raw.to_f/10" %>
        <%= slider min:20, max:100, value:24, binding: :min_payout_raw %> 
        
        max_payout: <%= text binding: :max_payout %>
        <%= calculated_var ":max_payout = :max_payout_raw.to_f/10" %>
        <%= slider min:20, max:100, value:25, binding: :max_payout_raw %> 
    </div>
    <div>
        min_amount: <%= text binding: :min_amount %>
        <%= slider min:0, max:50, value:20, binding: :min_amount %> 
        
        max_amount: <%= text binding: :max_amount %>
        <%= slider min:0, max:50, value:21, binding: :max_amount %> 
    </div>
</div>


<h3>==Segmentation==</h3>
total epoch = <%= text binding: :total %><br/>
segmentation epoch =  <%= text binding: :count %><br/><br/>
<%= chart binding: :seg_portion_chart %> <%= chart binding: :dist_chart1 %><%= chart binding: :dist_chart2 %> <%= chart binding: :dist_chart3 %><%= chart binding: :dist_chart4 %><br/>

ob avg payout (<%= text binding: :ob_avg_payout %>) -> round avg payout (<%= text binding: :round_avg_payout %>) <br/>
ob avg amount (<%= text binding: :ob_avg_amount %>) -> round avg amount (<%= text binding: :round_avg_amount %>) <br/>



<h3>==Simulation Metrics==</h3>
bet_amount: <%= text binding: :bet_amount %>
<%= calculated_var ":bet_amount = :bet_amount_raw.to_f/10" %>
<%= slider min:0, max:20, value:1, binding: :bet_amount_raw %> 

bet_bull_ratio: <%= text binding: :bet_bull_ratio %> <br/>
right_bet_ratio: <%= text binding: :right_bet_ratio %> <br/>
win_bet_ratio: <%= text binding: :win_bet_ratio %> <br/>
max_trace: <%= text binding: :max_trace %> <br/>
return_amt: <%= text binding: :ret_amount %> <br/>

<% calculated_var ":calc = $data['seg'.to_sym].calc(:epoch_begin,:epoch_end,:min_payout, :max_payout, :min_amount, :max_amount, :bet_amount)" %>
<% calculated_var ":count = :calc['count'.to_sym]" %>
<% calculated_var ":ob_avg_payout = :calc['ob_avg_payout'].round(2)" %>
<% calculated_var ":ob_avg_amount = :calc['ob_avg_amount'].round(2)" %>
<% calculated_var ":ob_payout_arr = :calc['ob_payout_arr']" %>
<% calculated_var ":ob_amount_arr = :calc['ob_amount_arr']" %>
<% calculated_var ":round_avg_payout = :calc['round_avg_payout'].round(2)" %>
<% calculated_var ":round_avg_amount = :calc['round_avg_amount'].round(2)" %>
<% calculated_var ":round_payout_arr = :calc['round_payout_arr']" %>
<% calculated_var ":round_amount_arr = :calc['round_amount_arr']" %>
<% calculated_var ":ret_amount = :calc['ret_amount'].round(2)" %>
<% calculated_var ":max_trace = :calc['max_trace'].round(2)" %>
<% calculated_var ":win_bet_ratio = :calc['win_bet_ratio'].round(2)" %>
<% calculated_var ":right_bet_ratio = :calc['right_bet_ratio'].round(2)" %>
<% calculated_var ":bet_bull_ratio = :calc['bet_bull_ratio'].round(2)" %>
<% calculated_var ":total = :epoch_end.to_i - :epoch_begin.to_i + 1 " %>

<% calculated_var ':seg_portion_chart = pie_chart([{"category"=>"2-Other","value"=>:total-:count},{"category"=>"1-Segmentation","value"=>:count}],"Segmentation Portion")' %>
<% calculated_var ':dist_chart1 = dist_chart(:ob_payout_arr.map{|x| {"vals"=>x} },"ob payout")' %>
<% calculated_var ':dist_chart2 = dist_chart(:round_payout_arr.map{|x| {"vals"=>x} },"round payout")' %>
<% calculated_var ':dist_chart3 = dist_chart(:ob_amount_arr.map{|x| {"vals"=>x} },"ob amount")' %>
<% calculated_var ':dist_chart4 = dist_chart(:round_amount_arr.map{|x| {"vals"=>x} },"round amount")' %>

EOS


RenderWrap.jsrb = <<~EOS
    $document.at_css("#btn").inner_html="999"
EOS

    RenderWrap[:epoch_begin] = epoch_begin
    RenderWrap[:epoch_end] = epoch_end
    RenderWrap[:seg] = seg
    RenderWrap.data
end

