__TASK_NAME__ = "uniswap/simulation_class_v4"

load(Task.load("base/render_wrap"))

require 'objspace'


class Timer 
    attr_accessor :sim_time, :sim_time_end, :sim_time_ts, :sim_time_end_ts, :time_source
    def init(sim_time, sim_time_end, sim_time_ts, sim_time_end_ts, time_source)
        @sim_time = sim_time
        @sim_time_end = sim_time_end
        @sim_time_ts = sim_time_ts
        @sim_time_end_ts = sim_time_end_ts
        @time_source = time_source
    end

    
end

class Simulation < MappingObject
    def self.task
        return "uniswap/simulation_class_v4"
    end
    
    mapping_accessor :hedge, :swap_price, :swap_price_cex, :time_table, :uni, :pool, :bot, :cur_time, :sim_data, :user_pool, :reversed
    mapping_accessor :sim_time, :sim_time_end, :sim_time_ts, :sim_time_end_ts
    mapping_accessor :load_action, :pool_id, :exchange, :sim_queue, :config
    
    def sim_time_ts
        return self.time_table.find_ts_by_id(self.sim_time.to_i)
    end

    def sim_time_end_ts
        return self.time_table.find_ts_by_id(self.sim_time_end.to_i)
    end
    
    def bot_stats
        if self.sim_data!=nil and self.sim_data!=[] then
            return {
                total_pnl:self.sim_data[-1][:total_pnl],
                unhedged_pnl:self.sim_data[-1][:unhedged_pnl],
                roi_percent:self.sim_data[-1][:roi_percent],
                
                dex_fee:self.sim_data[-1][:total_fee],
                cex_fee:self.sim_data[-1][:cex_fee],
                value_diff:self.sim_data[-1][:value_diff],
            }
        else
            return {}
        end
    end    
    
    def run_load_action
        return if self.load_action==nil
        if self.load_action == "run_simulation" or self.load_action == "run_simulation_queue" then
            # $logger.call "run simulation #{self.sim_time} - #{self.sim_time_end}"
            # self.simulate(self.sim_time,self.sim_time_end)
            # self.load_action = nil
        else 
            ## load action seq
            self.load_action.split("|").map do |cmd|
                if cmd =~ /init_pool/ then
                    param = cmd.split("@")
                    param.shift
                    param = param.join("@").split(",")
                    pool_id = param[0]
                    exchange = param[1]
                    
                    $logger.call "==[load_action]== init_pool #{pool_id} #{exchange}"
                    
                    self.user_pool = []
                    self.cur_time = 99999999
                    self.sim_data = []
                    self.sim_queue = []
                    self.config = {}
                    self.data_import(pool_id,exchange)
                end
                if cmd =~ /change_time/ then
                    param = cmd.split("@")
                    param.shift
                    param = param.join("@").split(",")
                    time0 = param[0]
                    time1 = param[1]
                    
                    self.sim_time = self.time_table.find_id_by_str(time0)
                    self.sim_time_end = self.time_table.find_id_by_str(time1)
                    self.sim_time_ts  = self.time_table.find_ts_by_str(time0)
                    self.sim_time_end_ts  = self.time_table.find_ts_by_str(time1)
                    
                    self.change_time(self.sim_time)

                    $logger.call "==[load_action]== change_time #{time0} #{time1} => #{self.sim_time} #{self.sim_time_end}"
                end
                if cmd =~ /add_liqudity/ then
                    param = cmd.split("@")
                    param.shift
                    param = param.join("@").split(",")
                    price_a_mul = param[0].to_f
                    price_b_mul = param[1].to_f
                    total_token = param[2].to_f

                    price = self.uni.price
                    price_a = self.uni.price * (100+price_a_mul)/100 
                    price_b = self.uni.price * (100+price_b_mul)/100 

                    x,y,l = self.uni.calc_add_liquidity_ratio(price_a, price_b)
                    
                    f = total_token / (x*price + y)
                    token0 = x * f
                    token1 = y * f

                    self.uni.clean_liquidity("user");
                    self.uni.add_liquidity(token0,token1,price_a,price_b,"user"); 
                    self.pool.init()
                    self.pool.reset(self.uni.liquidity_pool)
                    self.uni.liquidity_pool = self.pool.calc_pool(-1, self.uni.liquidity_pool.filter {|x| x[:sender]=='user'}, ->() { self.uni.mark_slice_pool_dirty() } )
                    self.uni.mark_slice_pool_dirty()

                    $logger.call "==[load_action]== add_liqudity #{price_a_mul} #{price_b_mul} #{total_token} => #{price} #{price_a} #{price_b} #{total_token} #{token0} #{token1} #{self.uni.liquidity_pool.filter {|x| x[:sender]=='user'} }"
                end
                if cmd =~ /run_simulation_queue/ then
                    $logger.call "==[run_simulation_queue]=="

                    timer = Timer.new
                    timer.init(self.sim_time,self.sim_time_end,self.sim_time_ts,self.sim_time_end_ts,self.bot.config[:time_source])
                    self.simulate(timer)
                    $logger.call "bot_stats = #{JSON.dump(self.bot_stats())}"
                    self.load_action = "run_simulation_queue"
                end
            end
        end
    end
    
    def init(pool_id,exchange)
        self.uni = UniswapV3.new
        self.hedge = Hedge.new()
        self.swap_price = SwapPriceDex.new()
        self.swap_price_cex = SwapPriceCexSynthesis.new()
        self.time_table = TimeTable.new()
        self.bot = Bot.new
        self.pool = Pool.new

        self.user_pool = []
        self.cur_time = 99999999
        self.sim_data = []
        self.sim_queue = []
        self.config = {}
        
        self.data_import(pool_id,exchange) 
    end
    
    
    def price
        self.uni.price
    end
    
    # def time
    #     self.time_table.find_ts_by_id(self.cur_time)[:time]
    # end
    
    def chart(price_a=nil,price_b=nil)
            title = "Simulation Result"
            
            min_price = (self.sim_data).map {|x| x[:price]}.min
            max_price = (self.sim_data).map {|x| x[:price]}.max
            

            if price_a!=nil and min_price!=nil then
                min_price = price_a if price_a < min_price 
            end
            if price_b!=nil and min_price!=nil then
                max_price = price_b if price_b > max_price
            end
            

            chart ={
                  "title": title,
                  "data": {
                    "values": self.sim_data.map {|x| x[:cex_fee]=-x[:cex_fee]; x}
                  },
  "vconcat": [
    {
      "hconcat": [
        {
          "width": 600,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {
                  "field": "price",
                  "type": "quantitative",
                  "scale": {"domain": [min_price, max_price]}
                },
                "tooltip": [{"field": "time_str"}, {"field": "price"}]
              }
            },
            {
              "mark": "rule",
              "encoding": {
                "y": {"datum": price_a, "type": "quantitative"},
                "color": {"value": "blue"},
                "size": {"value": 1},
                "tooltip": [{"field": "time_str"}, {"field": "price"}]
              }
            },
            {
              "mark": "rule",
              "encoding": {
                "y": {"datum": price_b, "type": "quantitative"},
                "color": {"value": "blue"},
                "size": {"value": 1},
                "tooltip": [{"field": "time_str"}, {"field": "price"}]
              }
            }
          ]
        },
        {
          "width": 300,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "bar",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "volume0", "type": "quantitative"},
                "tooltip": [{"field": "time_str"}, {"field": "volume0"}]
              }
            }
          ]
        },
        {
          "width": 300,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "bar",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "volume1", "type": "quantitative"},
                "tooltip": [{"field": "time_str"}, {"field": "volume1"}]
              }
            }
          ]
        }
      ]
    },
    {
      "hconcat": [
        {
          "width": 600,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "area",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "cex_position", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "cex_position"},
                  {"field": "token0_amt"}
                ]
              }
            },
            {
              "mark": {
                "type": "area",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "token0_amt", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "cex_position"},
                  {"field": "token0_amt"}
                ]
              }
            }
          ]
        },
        {
          "width": 300,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "area",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "token0_fee", "type": "quantitative"},
                "tooltip": [{"field": "time_str"}, {"field": "token0_fee"}]
              }
            }
          ]
        },
        {
          "width": 300,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "area",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "token1_fee", "type": "quantitative"},
                "tooltip": [{"field": "time_str"}, {"field": "token1_fee"}]
              }
            }
          ]
        }
      ]
    },
    {
      "hconcat": [
        {
          "width": 600,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "value_diff", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "total_pnl"},
                  {"field": "unhedged_pnl"}
                ]
              }
            },
            {
              "mark": "rule",
              "encoding": {
                "y": {"datum": 0, "type": "quantitative"},
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
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after",
                "color": "green"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "total_fee", "type": "quantitative"},
                "tooltip": [
                  {"field": "total_fee"},
                  {"field": "cex_fee"},
                ]
              }
            },
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after",
                "color": "orange"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "cex_fee", "type": "quantitative"},
                "tooltip": [
                  {"field": "total_fee"},
                  {"field": "cex_fee"},
                ]
              }
            },
            {
              "mark": "rule",
              "encoding": {
                "y": {"datum": 0, "type": "quantitative"},
                "color": {"value": "red"},
                "size": {"value": 1}
              }
            }
          ]
        }
      ]
    },
    {
      "hconcat": [
        {
          "width": 600,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "value_diff_dex_value", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "value_diff_dex_value"}
                ]
              }
            },
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after",
                "color": "green"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "total_fee", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "value_diff_dex_value"}
                ]
              }
            },            
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after",
                "color": "orange"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "cex_fee", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "value_diff_dex_value"},
                  {"field": "cex_fee"},
                  {"field": "total_fee"}
                ]
              }
            }
          ]
        },
        {
          "width": 600,
          "height": 200,
          "layer": [
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "total_pnl", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "total_pnl"},
                  {"field": "unhedged_pnl"}
                ]
              }
            },
            {
              "mark": {
                "type": "line",
                "line": true,
                "interpolate": "step-after",
                "color": "lightblue"
              },
              "encoding": {
                "x": {"field": "time", "type": "temporal"},
                "y": {"field": "unhedged_pnl", "type": "quantitative"},
                "tooltip": [
                  {"field": "time_str"},
                  {"field": "total_pnl"},
                  {"field": "unhedged_pnl"}
                ]
              }
            },
            {
              "mark": "rule",
              "encoding": {
                "y": {"datum": 0, "type": "quantitative"},
                "color": {"value": "red"},
                "size": {"value": 1}
              }
            }
          ]
        }
      ]
    }
  ]
}

    end
    
    def add_liquidity
      self.uni.update_lp_token;
    end
    
    def clean_liquidity
        self.uni.clean_liquidity('user');  
        self.pool.clean_liquidity('user');  
        self.user_pool = []        
    end

    def clean_fee
        self.uni.clean_fee('user');  
        self.pool.clean_fee('user');  
        self.user_pool = self.user_pool.map {|x| x[:token0_fee]=0; x[:token1_fee]=0; x}
        
    end
    
    def data_size_up()
        $logger.call "[#{Time.now}] ==begin data_size_up=="
        # $logger.call "swap_price.swap = #{self.swap_price.swap.to_s.size}"
        # $logger.call "pool.swap = #{self.pool.swap.to_s.size}"
        # $logger.call "pool.pool = #{self.pool.pool.to_s.size}"
        # $logger.call "time_table.time_table = #{self.time_table.time_table.to_s.size}"


        data_lood_from_redis(self.pool_id,self.exchange)
        self.uni.price = self.swap_price.get_last_price()

        # if sim.pool.swap.size>0 then
        #     block_number = sim.pool.swap[sim.sim_time][:block_number]
        #     sim.user_pool = sim.uni.liquidity_pool.filter {|x| x[:sender]=="user"}
        #     sim.pool.cur_blocknumber = 9999999999+1
        #     sim.uni.liquidity_pool = sim.pool.calc_pool(block_number,sim.user_pool)
        # end
        
        # $logger.call "swap_price.swap = #{self.swap_price.swap.to_s.size}"
        # $logger.call "pool.swap = #{self.pool.swap.to_s.size}"
        # $logger.call "pool.pool = #{self.pool.pool.to_s.size}"
        # $logger.call "time_table.time_table = #{self.time_table.time_table.to_s.size}"
        $logger.call "[#{Time.now}] ==end data_size_up=="
    end

    def data_size_down()
        $logger.call "[#{Time.now}] ==begin data_size_down=="

        self.swap_price.data_size_down()
        self.swap_price_cex.data_size_down(self)
        self.pool.data_size_down()
        self.uni.data_size_down()
        $logger.call "[#{Time.now}] ==end data_size_down=="
    end

    def data_lood_from_redis(pool_id,exchange)
        self.swap_price.load_from_redis(pool_id,self.uni,self.reversed)
        self.swap_price_cex.load_from_redis(exchange,uni.token0,uni.token1,"USDT") 
        self.time_table.load_from_redis(pool_id,self.uni,self.reversed)
        self.pool.load_from_redis(pool_id,self.uni,self.reversed)
    end
    
    def data_init_config(pool_id,exchange)
        pool_config = DataStore.get("uniswap.#{pool_id}")
        pool_config = reverse_pool(pool_config)
        
        token0 = pool_config[:token0]
        token1 = pool_config[:token1]
        token0_decimal = pool_config[:token0_decimal]
        token1_decimal = pool_config[:token1_decimal]
        dex_fee = pool_config[:dex_fee]
        cex_fee = pool_config[:cex_fee]
        
        self.uni.init(token0,token1,token0_decimal,token1_decimal,nil,dex_fee)
        self.hedge.init(token0,token1,cex_fee)
        self.pool.init()
    end
    
    def data_init_value()
        self.uni.price = self.swap_price.get_last_price()
        self.pool.reset()
        self.uni.liquidity_pool = self.pool.calc_pool(-1, [], ->() { self.uni.mark_slice_pool_dirty() } )
        self.sim_time = self.time_table.count-1
        self.sim_time_end = self.time_table.count-1
    end

    def data_import(pool_id="",exchange="okex")
        $logger.call "[#{Time.now}] ==begin data_import=="

        self.pool_id = pool_id
        self.exchange = exchange

        data_init_config(pool_id,exchange)
        data_lood_from_redis(pool_id,exchange)
        data_init_value()

        # $logger.call "self.uni.price - #{self.uni.price}"
        # $logger.call "self.swap_price.swap - #{self.swap_price.swap[0,10]}"
        # $logger.call "self.pool.pool - #{self.pool.pool[0,10]}"
        # $logger.call "self.pool.swap - #{self.pool.swap[0,10]}"

        $logger.call "[#{Time.now}] ==end data_import=="
    end 
    
    
    def change_time(id,run=false)
        change_time_by_id(id,run)
    end
    
    def change_time_by_id(id,run=false)
        ts = self.time_table.find_ts_by_id(id)
        self.swap_price_cex.change_time(ts)
        
        swap = self.swap_price.get_swap_by_id(id)
        price = swap[:price]
        volume0 = swap[:volume0]
        volume1 = swap[:volume1]


profiler_time1 = Time.now()
        self.uni.change_price(price,volume0,volume1,run)
$profiler[:change_price] = ($profiler[:change_price] or 0) + (Time.now()-profiler_time1)
        

        if self.pool.swap.size>0 then
            block_number = self.pool.swap[id][:block_number]
            self.user_pool = self.uni.liquidity_pool.filter {|x| x[:sender]=="user"}


profiler_time1 = Time.now()
            self.uni.liquidity_pool = self.pool.calc_pool(block_number,self.user_pool, ->() { self.uni.mark_slice_pool_dirty() })
$profiler[:calc_pool] = ($profiler[:calc_pool] or 0) + (Time.now()-profiler_time1)
        end

        self.cur_time = id
    end

    def change_time_by_ts(ts,run=false)
        id = self.time_table.get_id_by_ts(ts)
        change_time_by_id(id,run)
    end
    
    def simulate_tick_logic(time,time_end)

    profiler_time = Time.now()
        self.change_time_by_id(time,true)
    $profiler[:change_time] = ($profiler[:change_time] or 0) + (Time.now()-profiler_time)
    
    
    profiler_time = Time.now()

        time_ts = self.time_table.find_ts_by_id(time)
        time_str = self.time_table.time_str_by_id(time)

        uni_price = self.uni.price
        cex_price = nil
        
        if self.bot.config[:observation_price] == "uniswap" then
            price = uni_price
        end
        if self.bot.config[:observation_price] == "cex" then
            cex_price = self.swap_price_cex.get_swap_by_ts(time_ts) if cex_price==nil  # lazy eval
            price = cex_price
        end

        if self.bot.config[:settlement_price] == "uniswap" then
            self.hedge.set_price(uni_price)
        end
        if self.bot.config[:settlement_price] == "cex" then
            cex_price = self.swap_price_cex.get_swap_by_ts(time_ts) if cex_price==nil # lazy eval
            self.hedge.set_price(cex_price)
        end

        
        dprice = ((@saved_price == 0 ? 1 : price / @saved_price) - 1)*100
        @saved_price = price
        
    profiler_time1 = Time.now()
        volume0 = self.uni.adjd2d(self.swap_price.get_swap_by_id(self.cur_time)[:volume0],self.uni.token0_decimal).to_f
        volume1 = self.uni.adjd2d(self.swap_price.get_swap_by_id(self.cur_time)[:volume1],self.uni.token1_decimal).to_f
    $profiler[:uni_math] = ($profiler[:uni_math] or 0) + (Time.now()-profiler_time1)
        
        volume = volume0*price + volume1
        
        lp =  self.uni.liquidity_pool.filter{|x| x[:sender]!=nil}
        ul_ratio = self.uni.ul_ratio

        token0_amt = lp.map {|x| x[:token0]}.sum 
        token1_amt = lp.map {|x| x[:token1]}.sum
    profiler_time1 = Time.now()
        token0_fee = self.uni.adjd2d(lp.map {|x| x[:token0_fee]}.sum,self.uni.token0_decimal).to_f
        token1_fee = self.uni.adjd2d(lp.map {|x| x[:token1_fee]}.sum,self.uni.token1_decimal).to_f
    $profiler[:uni_math] = ($profiler[:uni_math] or 0) + (Time.now()-profiler_time1)
        total_fee = token0_fee*price + token1_fee
        dex_value = token0_amt*price + token1_amt
        ddex_value = (self.sim_data==[]) ? 0 : dex_value.to_f - self.sim_data[0][:dex_value]
        
    profiler_time1 = Time.now()
        bot_data = self.bot.run(self.hedge, time, time_ts, time_str,self.uni.price,token0_amt,token1_amt, token0_fee, token1_fee)
    $profiler[:bot_run] = ($profiler[:bot_run] or 0) + (Time.now()-profiler_time1)
        
        
    profiler_time1 = Time.now()
        cex_fee = self.hedge.get_fee
        cex_position = self.hedge.get_position("amt")
        cex_value = self.hedge.get_pnl("amt")
        cex_fee_position = self.hedge.get_position("fee")
        cex_fee_value = self.hedge.get_pnl("fee")
    $profiler[:cex_calc] = ($profiler[:cex_calc] or 0) + (Time.now()-profiler_time1)
        value_diff = cex_value + ddex_value
        value_diff_dex_value = ((self.sim_data==[]) ? 0 : value_diff / self.sim_data[0][:dex_value])*100
        

        total_pnl = total_fee + value_diff - cex_fee + cex_fee_value
        unhedged_pnl = total_fee + ddex_value
        
        roi = ((self.sim_data==[]) ? 0 :  total_pnl / self.sim_data[0][:dex_value])*100
        unhedged_roi = ((self.sim_data==[]) ? 0 :  unhedged_pnl / self.sim_data[0][:dex_value])*100
        column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff, :cex_fee_position, :cex_fee_value, :dprice_percent,:value_diff_dex_value_percent,:cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, :bot_output,:volume0,:volume1,:volume,:ul_ratio]

    $profiler[:calc_metric] = ($profiler[:calc_metric] or 0) + (Time.now()-profiler_time)

        sim_data_item = {id:time, 
                     time:time_str,
                     time_str:time_str,
                     price:price.round(8),
                     token0_amt:token0_amt.round(8),
                     token1_amt:token1_amt.round(8),
                     token0_fee:token0_fee.round(8), #8
                     token1_fee:token1_fee.round(8), #8
                     total_fee: total_fee.round(8), #8
                     dex_value: dex_value.round(8),
                     ddex_value: ddex_value.round(8),
                     cex_position:cex_position.round(8),
                     cex_value:cex_value.round(8),
                     value_diff: value_diff.round(8),
                     cex_fee_position:cex_fee_position.round(8),
                     cex_fee_value:cex_fee_value.round(8),
                     dprice_percent: dprice.round(8),
                     value_diff_dex_value_percent:value_diff_dex_value.round(8),
                     cex_fee:cex_fee.round(8),
                     total_pnl: total_pnl.round(8),
                     roi_percent:roi.round(8),
                     unhedged_pnl:unhedged_pnl.round(8),
                     unhedged_roi_percent:unhedged_roi.round(8),
                     volume:volume.round(8),
                     volume0:volume0.round(8),   
                     volume1:volume1.round(8),   
                     ul_ratio:ul_ratio.round(8), #4
                    }.merge(bot_data)

        self.sim_data.push(sim_data_item)
    end
    
    def simulate(time_start,time_end)
        self.sim_data = []
        self.hedge.reset
        self.bot.reset

        self.clean_fee
        @saved_price  = 0
        
        # run simulation in backend  
        sim_status = "#{Time.now} : Simulation Progress [#{time-time} / #{time_end-time}] : #{ObjectSpace.memsize_of_all/1_000_000} MB memory"
        $logger.call(sim_status)
        
        (time..time_end).each do |t| 
            if t % 100==0 then
                sim_status = "#{Time.now} : Simulation Progress [#{t-time} / #{time_end-time}] : #{ObjectSpace.memsize_of_all/1_000_000} MB memory"
                $logger.call(sim_status)
            end
            simulate_tick_logic(t,time_end)
        end
        
        sim_status = "#{Time.now} : Simulation Progress [#{time_end-time} / #{time_end-time}] : #{ObjectSpace.memsize_of_all/1_000_000} MB memory"
        $logger.call(sim_status)

        self.change_time(self.sim_time)
    end
    
    def reverse_pool(pool_config)
        if not (pool_config[:token1]=="USDT" or pool_config[:token1]=="USDC" or pool_config[:token1]=="ETH") then
            swap = pool_config[:token0]
            pool_config[:token0] = pool_config[:token1]
            pool_config[:token1] = swap
            
            swap = pool_config[:token0_decimal]
            pool_config[:token0_decimal] = pool_config[:token1_decimal]
            pool_config[:token1_decimal] = swap
            
            self.reversed = true
        end
        return pool_config
    end
end

def main()
end