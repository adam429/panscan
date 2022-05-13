__TASK_NAME__ = "uniswap/simulation"

load(Task.load("base/render_wrap"))


class Simulation 
    attr_accessor :dex, :cex, :uni, :pool, :bot
    
    def initialize(uni,dex,cex, pool ,bot)
        @uni = uni
        @dex = dex
        @cex = cex
        @bot = bot
        @pool = pool
        @time = 99999999
        @data = []
    end
    
    def price
        @uni.price
    end
    
    def time
        @dex.time_table[@time][:time]
    end
    
    def chart
            title = "Simulation Result"
    
            min_price = @data.map {|x| x[:price]}.min
            max_price = @data.map {|x| x[:price]}.max
            

            chart ={
                  "title": title,
                  "data": {
                    "values": @data.map {|x| x[:cex_fee]=-x[:cex_fee]; x}
                  },
  "vconcat": [
    {
      "width": 600,
      "height": 200,
      "layer": [
        {
          "mark": {"type": "line", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "price",
              "type": "quantitative",
              "scale": {"domain": [min_price,max_price]}
            },
            "tooltip": [{"field": "time"}, {"field": "price"}]
          }
        }
      ]      
    },
    {
      "width": 600,
      "height": 200,
      "layer": [
        {
          "mark": {"type": "line", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "total_pnl",
              "type": "quantitative",
            },
            "tooltip": [{"field": "time"}, {"field": "total_pnl"}]
          }
        },
        {
          "mark": "rule",
          "encoding": {
            "y": {
              "datum": 0,
              "type": "quantitative",
            },
            "color": {"value": "red"},
            "size": {"value": 1}
          }
        }

      ]      
    },
    {
      "width": 600,
      "height": 200,
      "layer": [
        {
          "mark": {"type": "area", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "cex_position",
              "type": "quantitative",
            },
            "tooltip": [{"field": "time"}, {"field": "cex_position"},  {"field": "token0_amt"}]
          },
        },
        {
          "mark": {"type": "area", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "token0_amt",
              "type": "quantitative",
            },
            "tooltip": [{"field": "time"}, {"field": "cex_position"},  {"field": "token0_amt"}]
          },
        }
      ]      
    },
    {
      "width": 600,
      "height": 200,
      "layer": [
        {
          "mark": {"type": "area", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "cex_fee",
              "type": "quantitative",
            },
            "tooltip": [{"field": "time"}, {"field": "cex_fee"}, {"field": "dex_fee"}]
          },
        },
        {
          "mark": {"type": "area", "line": true},
          "encoding": {
            "x": {"field": "time", "type": "temporal"},
            "y": {
              "field": "dex_fee",
              "type": "quantitative",
            },
            "tooltip": [{"field": "time"}, {"field": "cex_fee"}, {"field": "dex_fee"}]
          },
        }
      ]      
    },
  ]
}
    end


    def data_import(pool_id="")
        $logger.call "==begin data_import=="
        # read data from graph
        
        @dex.swap =  DataStore.get("uniswap.swap")
        @pool.swap = DataStore.get("uniswap.swap")
        @pool.pool = DataStore.get("uniswap.pool")
        @pool.init_tick = DataStore.get("uniswap.init_tick")
        block_to_time = DataStore.get("uniswap.time_table")

        # $logger.call "block_to_time=#{block_to_time[0]}"

        block_to_time = block_to_time.map {|x,y,z|  [x,[y,z]] }.to_h
        # $logger.call "block_to_time=#{block_to_time}"
        @dex.time_table = @dex.swap.map {|x| (block_to_time[x[:block_number]] or [0])[0] }
        # $logger.call "@dex.swap=#{@dex.swap[0,100]}"
        # $logger.call "time_table=#{@dex.time_table}"

        @dex.swap =  @dex.swap.map{|v| 
            price = 1.0001**v[:tick]
            {
                id:v[:id],
                time:block_to_time[v[:block_number]][0],
                price:price,
                volume0:v[:volume0],
                volume1:v[:volume1],
                volume:v[:volume1] + v[:volume0]*price,
            }
        }
        
        @uni.price = @dex.swap.last[:price]

        @uni.liquidity_pool = @pool.calc_pool(-1)
        $logger.call "==end data_import=="
    end 
    
    def change_time(new_time,run=false)
        return if @time == new_time

        price = @dex.swap[new_time][:price]
        volume0 = @dex.swap[new_time][:volume0]
        volume1 = @dex.swap[new_time][:volume1]
        # $logger.call "new_time = #{new_time} new_price = #{price} volume0 = #{volume0} volume1 = #{volume1}"
        
        @uni.change_price(price,volume0,volume1,run)
        block_number = @pool.swap[new_time][:block_number]
        $logger.call @pool.swap[new_time]
        $logger.call block_number

    
        @uni.liquidity_pool = @pool.calc_pool(block_number)
        @cex.set_price(price)


        @time = new_time
    end
    
    def simulate(time_start,time_end)
        data = []
        @cex.reset
        @bot.reset
        (time_start..time_end).each do |time| 
            # $logger.call "time - #{time}"
            
            sim_status = "#{time} / #{time_end}"
            $logger.call sim_status
            # $vars[:sim_status] = sim_status
            # calculated_var_update_all()

            self.change_time(time,true)
            time_str = @dex.time_str(time)
            price = self.price
            
            lp =  @uni.liquidity_pool.filter{|x| x[:sender]!=nil}
            # $logger.call lp
            token0_amt = lp.map {|x| x[:token0]}.sum 
            token1_amt = lp.map {|x| x[:token1]}.sum
            token0_fee = @uni.adjd2d(lp.map {|x| x[:token0_fee]}.sum,@uni.token0_decimal).to_f
            token1_fee = @uni.adjd2d(lp.map {|x| x[:token1_fee]}.sum,@uni.token1_decimal).to_f

            bot_data = @bot.run(@cex, time, time_str,@uni.price,token0_amt,token1_amt)
    
            cex_fee = -1*@cex.get_fee
            dex_value = token0_amt*price + token1_amt
            total_value = @cex.get_pnl + dex_value
            dex_fee = token0_fee*price + token1_fee
            
            data.push ( {id:time, 
                         time:time_str,
                         price:price,
                         token0_amt:token0_amt,
                         token1_amt:token1_amt,
                         token0_fee:token0_fee,
                         token1_fee:token1_fee,
                         dex_fee: dex_fee,
                         dex_value: dex_value,
                         cex_position:@cex.get_position,
                         cex_fee:cex_fee,
                         cex_value:@cex.get_pnl,
                         total_value: total_value,
                         value_diff: ((data==[]) ? 0 : total_value.to_f/data[0][:total_value]-1),
                         total_pnl: ((data==[]) ? 0 : total_value+dex_fee+cex_fee-data[0][:total_value]),
                        }.merge(bot_data))
        end
        # self.change_time($vars[:sim_time].to_i)
        @data = data
        return data
    end
end