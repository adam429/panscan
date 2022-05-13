__TASK_NAME__ = "uniswap/bot_adam"

load(Task.load("base/render_wrap"))

class Bot < MappingObject
    def reset
    end
    
    def bot_config
        config = {
            trigger_position:30000, 
            adj_position_ratio:1
        }        
    end
    
    def run(cex,time_id,time,price,token0_amt,token1_amt)
        config = self.bot_config

        delta_position = token0_amt + cex.get_position
        if delta_position.abs > config[:trigger_position] then
            short_position = config[:adj_position_ratio] * delta_position
            cex.adj_position( -1 * short_position)
            bot_output="#{ short_position>0 ? 'open' : 'close' } short position #{short_position.abs}"

            # $logger.call bot_action
        end
        # $logger.call "time = #{time_id} #{time} | price = #{price} | token0_amt = #{token0_amt} | token_1amt = #{token0_amt} | cex.position = #{cex.position}"
        
        return {bot_output:bot_output}
    end
end