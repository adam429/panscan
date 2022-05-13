__TASK_NAME__ = "team/uniswap/cex"

load(Task.load("base/render_wrap"))

class Cex < MappingObject
    def self.task
        return "team/uniswap/cex"
    end
    
    mapping_accessor :rate, :position, :fee, :price, :position_record, :token0, :token1
    
    def initialize
        super()
    end
        
    def init(init_token0,init_token1,init_rate)
        self.rate = init_rate
        self.token0 = init_token0
        self.token1 = init_token1
        self.position = 0
        self.fee = 0
        self.position_record = []
    end
    
    def reset
        self.position = 0
        self.fee = 0
        self.position_record = []
    end
        
    def set_rate(init_rate)
        self.rate = init_rate
    end
    
    def set_price(init_price)
        self.price = init_price
    end
    
    def adj_position(value)
        self.fee += value.abs * self.price * self.rate
        self.position += value
        self.position_record.push({:price=>self.price, :value=>value})
    end
    
    def get_position
        self.position
    end
    
    def get_pnl
        self.position_record.map {|x| (self.price-x[:price])*x[:value] }.sum
    end
    
    def get_fee
        self.fee
    end
    
    def stats
        $logger.call "price #{self.price} | fee #{self.fee} | position #{self.position} | pnl #{get_pnl} | record #{self.position_record}"
    end
end

def main
    cex = Cex.new
    cex.init("ETH","USDT",0.0004)

    cex.set_price(3000)
    cex.adj_position(-10)
    cex.stats
    cex.set_price(2000)
    cex.stats
    cex.adj_position(-10)
    cex.stats
    cex.set_price(1000)
    cex.stats
    cex.adj_position(10)
    cex.stats
    cex.set_price(0)
    cex.stats
    cex.set_price(4000)
    cex.stats    
    
    RenderWrap[:cex]=cex
    RenderWrap.data
end


