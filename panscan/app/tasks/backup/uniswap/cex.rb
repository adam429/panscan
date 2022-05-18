__TASK_NAME__ = "uniswap/cex"

load(Task.load("base/render_wrap"))

class Cex < MappingObject
    def self.task
        return "uniswap/cex"
    end
    
    mapping_accessor :rate, :position, :fee, :price, :position_record, :token0, :token1
    
    def initialize
        super()
    end
        
    def init(init_token0,init_token1,init_rate)
        self.rate = init_rate
        self.token0 = init_token0
        self.token1 = init_token1
        self.position = {}
        self.fee = {}
        self.position_record = {}
    end
    
    def reset
        self.position = {}
        self.fee = {}
        self.position_record = {}
    end
        
    def set_rate(init_rate)
        self.rate = init_rate
    end
    
    def set_price(init_price)
        self.price = init_price
    end
    
    def adj_position(value,group="all")

        self.fee[group] = 0 if self.fee[group]==nil
        self.fee[group] = self.fee[group] + value.abs * self.price * self.rate

        self.position[group] = 0 if self.position[group]==nil
        self.position[group] = self.position[group] + value

        self.position_record[group] = [] if self.position_record[group]==nil
        self.position_record[group].push({:price=>self.price, :value=>value})
    end
    
    def get_position(group="all")
        if group!="all" then
            return (self.position[group] or 0)
        else
            return self.position.map {|k,v| v}.sum
        end
    end
    
    def get_pnl(group="all")
        if group!="all" then
          self.position_record[group] = [] if self.position_record[group] == nil    
          return self.position_record[group].map {|x| (self.price-x[:price])*x[:value] }.sum
        else
          return self.position_record.map {|k,v|
            v.map {|x| (self.price-x[:price])*x[:value] }.sum    
          }.sum
        end
    end
    
    def get_fee(group="all")
        if group!="all" then
            return (self.fee[group] or 0)
        else
            return self.fee.map {|k,v| v}.sum
        end
    end
    
    def stats
        $logger.call "price #{self.price} | fee #{self.get_fee} | position #{self.get_position} | pnl #{self.get_pnl} | record #{self.position_record}"
    end
end

def main
    cex = Cex.new
    cex.init("ETH","USDT",0.0004)

    cex.set_price(3000)
    cex.adj_position(-10,"group_a")
    cex.stats
    cex.set_price(2000)
    cex.stats
    cex.adj_position(-10,"group_b")
    cex.stats
    cex.set_price(1000)
    cex.stats
    cex.adj_position(10,"group_c")
    cex.stats
    cex.set_price(0)
    cex.stats
    cex.set_price(4000)
    cex.stats    
    
    RenderWrap[:cex]=cex
    RenderWrap.data
end


