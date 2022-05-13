__TASK_NAME__ = "uniswap/bot"

load(Task.load("base/render_wrap"))

class Bot < MappingObject
    def self.task
        "uniswap/bot"
    end
    
    mapping_accessor :config
    
    def initialize()
        super()
        
        self.config = {
            trigger_position:0.1, 
            adj_position_ratio:1
        }        
    end
    
    def config_format
        [
            {name: :trigger_position, value:self.config[:trigger_position], min:0, max:10, step:0.1 }, 
            {name: :adj_position_ratio, value:self.config[:adj_position_ratio], min:0, max:2, step:0.1 },
        ]        
    end
    
    def reset
    end
    
    def set_config(config)
        self.config = config
    end
    
    def get_config()
        return self.config
    end
    
    
    def run(cex,time_id,time_ts,time,price,token0_amt,token1_amt)
        config = self.get_config

        delta_position = token0_amt + cex.get_position
        if delta_position.abs > config[:trigger_position].to_f then
            short_position = config[:adj_position_ratio].to_f * delta_position
            cex.adj_position( -1 * short_position)
            bot_output="#{ short_position>0 ? 'open' : 'close' } short position #{short_position.abs}"

            # $logger.call bot_action
        end
        # $logger.call "time = #{time_id} #{time} | price = #{price} | token0_amt = #{token0_amt} | token_1amt = #{token0_amt} | cex.position = #{cex.position}"
        
        return {bot_output:bot_output}
    end
end