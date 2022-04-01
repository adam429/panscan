__TASK_NAME__ = "panbot/simulation/panbot_simulation_segmentation_interactive"


load(Task.load("base/database"))
load(Task.load("panbot/simulation/panbot_simulation_runner"))
load(Task.load("panbot/bot/panbot_payout_bot"))
load(Task.load("panbot/panbot_stats"))
load(Task.load("base/logger"))

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))


class Obj < MappingObject
    attr_accessor :foo

    def to_data
        foo
    end
    
    def from_data(data)
        self.foo = data
    end
end

def main
    RenderWrap.load(Task.load("#{$task.name}::calc_window"))
    
    database_init()
    
    epoch_begin = __epoch_begin__
    epoch_end = __epoch_end__

    data = Epoch.where(" ? <= epoch and epoch <= ? ",epoch_begin,epoch_end).map do |epoch|
        block = epoch.lock_block_number-3
        
        bull_payout = 0
        bear_payout = 0
        bull_amount = epoch.get_bull_amount(block)
        bear_amount = epoch.get_bear_amount(block)
        
        total_amount = bull_amount + bear_amount
        if total_amount == 0 then
            bull_payout = 0
            bear_payout = 0
        else
            bull_payout =  total_amount / bull_amount
            bear_payout=  total_amount / bear_amount
        end
        
        { 
            epoch:epoch.epoch,
            ob_payout:[bull_payout,bear_payout].max, 
            ob_amount:total_amount
        }
    end
    
    obj = Obj.new()
    obj.foo = "this is a foo object"


    RenderWrap.html = 
'''
<h1>Panbot Simulation Segmentation Interactive</h1>

min_payout: <%= text binding: :min_payout %>
<%= calculated_var ":min_payout = :min_payout_raw.to_f/10" %></br>
<%= slider min:20, max:100, value:24, binding: :min_payout_raw %> 

max_payout: <%= text binding: :max_payout %>
<%= calculated_var ":max_payout = :max_payout_raw.to_f/10" %></br>
<%= slider min:20, max:100, value:25, binding: :max_payout_raw %> 

min_amount: <%= text binding: :min_amount %>
<%= slider min:0, max:30, value:20, binding: :min_amount %> 

max_amount: <%= text binding: :max_amount %>
<%= slider min:0, max:30, value:21, binding: :max_amount %> 

<%= data[:obj].foo %>
'''

    RenderWrap[:data] = data
    RenderWrap[:obj] = obj

    RenderWrap.data
end

