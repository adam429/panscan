__TASK_NAME__ = "team/uniswap/bot_v2"

load(Task.load("base/render_wrap"))

class Bot < MappingObject
    def self.task
        return "team/uniswap/bot_v2"
    end
        
    mapping_accessor :config
    
    def initialize()
        super()
        
        self.config = {
            trigger_position:0.1, 
            trigger_price:10, 
            trigger_time_buffer:30,
            
            adj_position_ratio:1,
        }        
    end
    
    def config_format
        [
            {name: :trigger_position, value:self.config[:trigger_position], min:0, max:10, step:0.1 }, 
            {name: :trigger_price, value:self.config[:trigger_price], min:0, max:10, step:0.1 }, 
            {name: :trigger_time_buffer, value:self.config[:trigger_time_buffer], min:0, max:120, step:1 }, 

            {name: :adj_position_ratio, value:self.config[:adj_position_ratio], min:0, max:2, step:0.1 },
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
    
    def run(cex,time_id, time_ts ,time,price,token0_amt,token1_amt)
        config = self.get_config

        delta_position = token0_amt + cex.get_position
        delta_price = (price-@last_action[:price])
        observation = [delta_position,delta_price] 
        
        trigger = []
        trigger[0] = delta_position.abs >= config[:trigger_position].to_f
        trigger[1] = delta_price.abs >= config[:trigger_price].to_f
        
        if trigger.filter {|x| x==true }.size>0
            #update time buffer
            @time_buffer = time_ts if @time_buffer==-1
            
            if time_ts - @time_buffer >= config[:trigger_time_buffer] then
                
                # action
                short_position = config[:adj_position_ratio].to_f * delta_position
                cex.adj_position( -1 * short_position)
                
                @last_action[:price] = price
                @last_action[:time] = time
                
                bot_output="#{ short_position>0 ? 'open' : 'close' } short position #{short_position.abs}"
            end
        else
            # clean time buffer
            @time_buffer = -1
        end
        
        return {bot_output:bot_output,observation:observation.join("/"),trigger:trigger.join("/"),time_buffer: @time_buffer==-1 ? -1 : time_ts - @time_buffer}
    end
end