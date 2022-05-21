__TASK_NAME__ = "uniswap/bot_v3"

load(Task.load("base/render_wrap"))

class Bot < MappingObject
    def self.task
        return "uniswap/bot_v3"
    end
        
    mapping_accessor :config
    
    def initialize()
        super()
        
        self.config = {
            cex_data_source: "okex",
            base_currency: "ETH",
            time_source: "t1",
            
            amt_hedge:"true",
            fee_hedge:"true",
            
            observation_price: "uniswap",
            settlement_price: "uniswap",
            hedge_method: "h1",

            trigger_position:0.1, 
            trigger_price:0.1, 
            trigger_time_buffer:0,
            
            adj_position_ratio:1,
        }        
    end
    
    def config_format
        [
            {group: {name: "==Basic Config==", widgets:[
                {select:{name: :cex_data_source, value:self.config[:cex_data_source], option:["Okex"], option_value:["okex"] }}, 
                {select:{name: :base_currency, value:self.config[:base_currency], option:["ETH","USD"], option_value:["ETH","USD"] }}, 
                {select:{name: :time_source, value:self.config[:time_source], option:["t1 - Uniswap Discrete Tick Time","t2 - Absoulte Continuous Time (51)" ], option_value:["t1","t2"] }}, 
            ]}},
            
            {group: {name: "==Hedge Config==", widgets:[
                {select:{name: :amt_hedge, value:self.config[:amt_hedge], option:["True","False"], option_value:["true","false"] }}, 
                {select:{name: :fee_hedge, value:self.config[:fee_hedge], option:["True","False"], option_value:["true","false"] }}, 
                {select:{name: :observation_price, value:self.config[:observation_price], option:["Cex","Uniswap"], option_value:["cex","uniswap"] }}, 
                {select:{name: :settlement_price, value:self.config[:settlement_price], option:["Cex","Uniswap"], option_value:["cex","uniswap"] }}, 
                {select:{name: :hedge_method, value:self.config[:hedge_method], option:["h1 - use TOKEN0/USDT hedge as if it is TOKEN0/TOKEN1", "h2 - use TOKEN0/TOKEN1 hedge", "h3 - use synthesis TOKEN0/TOKEN1 hedge (TOKEN0/USDT + TOKEN1/USDT)"], option_value:["h1","h2","h3"] }}, 
            ]}},



            {group: {name: "==Trigger==", widgets:[
                {slider:{name: :trigger_position, value:self.config[:trigger_position], min:0, max:10, step:0.1 }}, 
                {slider:{name: :trigger_price, value:self.config[:trigger_price], min:0, max:10, step:0.1 }}, 
                {slider:{name: :trigger_time_buffer, value:self.config[:trigger_time_buffer], min:0, max:120, step:1 }}, 
            ]}},

            {group: {name: "==Action==", widgets:[
                {slider:{name: :adj_position_ratio, value:self.config[:adj_position_ratio], min:0, max:2, step:0.1 }},
            ]}},

            


        ]        
    end
    
    def reset
        @last_action = { price:-1, time:-1 }
        @time_buffer = -1
    end
    
    def set_config(config)
        self.config = config
    end
    
    def get_config()
        return self.config
    end
    
    def run(hedge,  time_ts, time, price, token0_amt, token1_amt, token0_fee, token1_fee)
        config = self.get_config
        
        total_hedge_position = (config[:amt_hedge]=="true" ? token0_amt : 0 ) + (config[:fee_hedge]=="true" ? token0_fee : 0 )

        # delta_position = total_hedge_position + cex.get_position
        # hedge_position_percent = cex.get_position / total_hedge_position

        delta_position = total_hedge_position
        if config[:adj_position_ratio].to_f.abs > 1e-8 then
             delta_position = total_hedge_position + hedge.get_position / config[:adj_position_ratio].to_f             
        end
        # $logger.call "total_hedge_position = #{total_hedge_position} | cex.get_position = #{cex.get_position} | delta_position = #{delta_position}"
        
        delta_price = (price-@last_action[:price])
        observation = [delta_position,delta_price] 
        
        trigger = []
        trigger[0] = delta_position.abs >= config[:trigger_position].to_f
        trigger[1] = delta_price.abs >= config[:trigger_price].to_f
        
        if trigger.filter {|x| x==true }.size>0
            #update time buffer
            @time_buffer = time_ts if @time_buffer==-1
            
            if time_ts - @time_buffer >= config[:trigger_time_buffer] then
                
                fee_short_position = (config[:fee_hedge]=="true" ? config[:adj_position_ratio].to_f * token0_fee : 0) + hedge.get_position("fee")
                amt_short_position = (config[:amt_hedge]=="true" ? config[:adj_position_ratio].to_f * token0_amt : 0) + hedge.get_position("amt")
                short_position = fee_short_position+amt_short_position
                
                hedge.adj_position( -1 * fee_short_position, "fee")
                hedge.adj_position( -1 * amt_short_position, "amt")


                @last_action[:price] = price
                @last_action[:time] = time
                
                bot_output="#{ short_position>0 ? 'open' : 'close' } short position #{amt_short_position.abs}+#{fee_short_position.abs}  make #{total_hedge_position} * #{config[:adj_position_ratio].to_f} hedged"
            end
        else
            # clean time buffer
            @time_buffer = -1
        end
        
        return {bot_output:bot_output,observation:observation.join("/"),trigger:trigger.join("/"),time_buffer: @time_buffer==-1 ? -1 : time_ts - @time_buffer}
    end
end