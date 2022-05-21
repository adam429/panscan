__TASK_NAME__ = "uniswap/swap_price"
__ENV__ = 'ruby3'
# load(Task.load("base/render_wrap"))   

CHART_TIME_INTERVAL = 3600

class TimeTable < MappingObject
    def self.task
        return "uniswap/swap_price"
    end

    mapping_accessor :time_table,:time_table_reverse
    
    def load_from_redis(pool_id,uni,reversed=false)
        swap =  DataStore.get("uniswap.#{pool_id}.swap")

        block_to_time = DataStore.get("uniswap.#{pool_id}.time_table")
        block_to_time = block_to_time.map {|x,y,z|  [x,[y,z]] }.to_h
        
        self.time_table = swap.map {|x| (block_to_time[x[:block_number]] or [0])[0] }
        self.time_table_reverse = self.time_table.reverse
            
    end
    
    def count
        self.time_table.count
    end
    
    # time_id to "2022-02-02 02:02:02" format    
    def time_str_by_id(id)
        return Time.at(self.time_table[id]).utc.to_s[0,19] if self.time_table[id]
    end

    def time_str_by_ts(ts)
        return Time.at(ts).utc.to_s[0,19]
    end
    
    # time_id to "2022-02-02T02:02" format    
    def time_str_widget_by_id(id)
        str = time_str_by_id(id)
        str[0,16].gsub(/ /,"T")
    end

    # str "2022-02-02T02:02" to time_id
    # str "2022-02-02 02:02:02" to time_id
    def find_id_by_str(str)
        arr = str.gsub(/T/,"-").gsub(/:/,"-").gsub(/ /,"-").split("-")
        time = Time.utc(arr[0],arr[1],arr[2],arr[3],arr[4]).to_i if arr.size==5
        time = Time.utc(arr[0],arr[1],arr[2],arr[3],arr[4],arr[5]).to_i if arr.size==6
        find_id_by_ts(time)
    end

    def find_ts_by_str(str)
        arr = str.gsub(/T/,"-").gsub(/:/,"-").gsub(/ /,"-").split("-")
        time = Time.utc(arr[0],arr[1],arr[2],arr[3],arr[4]).to_i if arr.size==5
        time = Time.utc(arr[0],arr[1],arr[2],arr[3],arr[4],arr[5]).to_i if arr.size==6
        time
    end

    
    # look up time_table
    def find_ts_by_id(id)
        self.time_table[id]
    end
    
    def find_id_by_ts(ts)
        return self.time_table_reverse.bsearch_index {|x| x<=ts}
        # ret = nil
        # self.time_table.each_with_index {|x,i|
        #     if x >= ts then 
        #         ret=i; 
        #         break; 
        #     end 
        # }
        # ret = self.time_table.size-1 if ret==nil
        # return ret
    end

end

class SwapPriceBase < MappingObject
    def self.task
        return "uniswap/swap_price"
    end

    mapping_accessor :swap, :swap_chart, :time_table

    def time_interval
        return [self.time_table[0],self.time_table[-1]]
    end
    
    def data_size_down()
        self.swap = self.swap.map {|v| { id:v[:id],time:v[:time],price:v[:price],volume:v[:volume] } }
        self.swap_chart = []

        last_time = 0
        volume = 0
        self.swap.map.with_index {|x,i| 
            if x[:time]-last_time>CHART_TIME_INTERVAL then
              self.swap_chart.push({x:i, time:x[:time], time_str:Time.at(x[:time]).to_s[0,19], price:x[:price], volume:(x[:volume]+volume) }) 
              last_time = x[:time]
              volume = 0
            else
              volume = volume + x[:volume]
            end
        }
    end

    def get_swap_by_id(id)
        return self.swap[id]
    end
    
    def get_swap_by_ts(ts)
        # ret = nil
        # self.time_table.each_with_index {|x,i|
        #     if x >= ts then 
        #         ret=i; 
        #         break; 
        #     end 
        # }
        # ret = self.time_table.size-1 if ret==nil
        # return self.swap[ret]
        
        # return self.swap.filter {|x| x[:time]>ts}[0]
        raise "here"
    end
    
    def get_last_price()
        return swap.last[:price]        
    end
    
    def select_swap(begin_time,end_time)
        self.swap.filter {|x| begin_time <= x[:time] and x[:time] <= end_time}        
    end

    # calc price_in_range percentage
    def price_in_range_from(price_a, price_b, from)
        select_price = swap[from,swap.size]
        select_price.filter {|x| price_a <= x[:price] and x[:price] <= price_b }.count / select_price.count.to_f
    end

    # calc price_in_range percentage
    def price_in_range_from_to(price_a, price_b, from, to)
        return 0 if to<from
        select_price = swap[from,to-from+1]
        select_price.filter {|x| price_a <= x[:price] and x[:price] <= price_b }.count / select_price.count.to_f
    end

    
    def clean_price_volume_chart
        return @price_volume_chart = nil
    end

    def price_volume_chart(price_a=nil,price_b=nil,cur_price=nil,sim_time=0,sim_time_end=0)
            return @price_volume_chart if @price_volume_chart 
            title = "Price & Volume"
            
            # data = swap.map.with_index {|x,i| {x:i, time:x[:time], time_str:Time.at(x[:time]).to_s[0,19], price:x[:price], volume:x[:volume] } }
            data = swap_chart
            
            last_price = data[-1][:price]
            data = data.filter {|x| x[:price] <= last_price * 50}
            min_price = data.map {|x| x[:price]}.min
            max_price = data.map {|x| x[:price]}.max
            min_price = min_price*0.7
            max_price = max_price*1.3
            

            @price_volume_chart ={
                  "title": title,
                  "data": {
                    "values": data
                  },
                  "vconcat": [
                      {
                          "width": 500,
                          "height": 200,
                          "layer":[
                                {
                                  "mark": {"type": "line", "line": true,"interpolate": "step-after"},
                                  "encoding": {
                                    "x": {"field": "time", "type": "temporal"},
                                    "y": {"field": "price", "type": "quantitative", "scale": {"domain": [min_price,max_price]} },
                                    "tooltip": [
                                      {"field": "time_str"},
                                      {"field": "price"}
                                    ]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": self.time_table[sim_time],
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price"}]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": self.time_table[sim_time_end],
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price"}]
                                  }
                                }
                          ]
                    },
        
                    {
                          "width": 500,
                          "height": 100,
                          "layer":[
                              {
                                  "mark": {
                                    "type": "bar",
                                    "line": true
                                  },
                                  "encoding": {
                                    "x": {"field": "time", "type": "temporal"},
                                    "y": {"field": "volume", "type": "quantitative"},
                                    "tooltip": [
                                      {"field": "time_str"},
                                      {"field": "volume"}
                                    ]
                                  }
                              },
                              {
                              "mark": "rule",
                              "encoding": {
                                "x": {
                                  "datum": self.time_table[sim_time],
                                  "type": "temporal"
                                },
                                "color": {"value": "red"},
                                "size": {"value": 1},
                                "tooltip": [{"field": "time_str"}, {"field": "price"}]
                                  }
                              },
                              {
                              "mark": "rule",
                              "encoding": {
                                "x": {
                                  "datum": self.time_table[sim_time_end],
                                  "type": "temporal"
                                },
                                "color": {"value": "red"},
                                "size": {"value": 1},
                                "tooltip": [{"field": "time_str"}, {"field": "price"}]
                              }                              
                            }
                          ]
                    }
                  ]
                }        
                
            @price_volume_chart["vconcat"][0]["layer"].push({
                          "mark": "rule",
                          "encoding": {
                            "y": {"datum": price_a, "type": "quantitative", "scale": {"domain": [min_price,max_price]}},
                            "color": {"value": "blue"},
                            "size": {"value": 1}
                          }
                        }) if min_price <= price_a and price_a<=max_price

            @price_volume_chart["vconcat"][0]["layer"].push({
                          "mark": "rule",
                          "encoding": {
                            "y": {"datum": price_b, "type": "quantitative", "scale": {"domain": [min_price,max_price]}},
                            "color": {"value": "blue"},
                            "size": {"value": 1}
                          }
                        }) if min_price <= price_b and price_b<=max_price
                        
            @price_volume_chart["vconcat"][0]["layer"].push({
                          "mark": "rule",
                          "encoding": {
                            "y": {"datum": cur_price, "type": "quantitative", "scale": {"domain": [min_price,max_price]}},
                            "color": {"value": "grey"},
                            "size": {"value": 1}
                          }
                        }) if min_price <= cur_price and cur_price<=max_price

            @price_volume_chart
    end
    
end

class SwapPriceDex < SwapPriceBase
    def self.task
        return "uniswap/swap_price"
    end

    def load_from_redis(pool_id,uni,reversed=false)
        self.swap =  DataStore.get("uniswap.#{pool_id}.swap")

        if reversed then
            self.swap = self.swap.map {|x|
                x[:tick] = -1*x[:tick]
                swap = x[:volume0]
                x[:volume0] = x[:volume1]
                x[:volume1] = swap
                x                
            }
        end

        block_to_time = DataStore.get("uniswap.#{pool_id}.time_table")
        block_to_time = block_to_time.map {|x,y,z|  [x,[y,z]] }.to_h

        self.swap =  self.swap.map{|v| 
            price = 1.0001**v[:tick]
            {
                id:v[:id],
                time:block_to_time[v[:block_number]][0],
                price:uni.adjp2p(price),
                volume0:v[:volume0],
                volume1:v[:volume1],
                volume:v[:volume1] + v[:volume0]*price,
            }
        }
        self.time_table = self.swap.map {|x| x[:time] }
    end
    
end

class SwapPriceCex < MappingObject
    mapping_accessor :token0, :token1
    mapping_accessor :realtime, :history, :realtime_reverse, :history_reverse
    
    def self.task
        return "uniswap/swap_price"
    end

    def data_size_down(sim)
        self.realtime = []
        self.history = []
        self.realtime_reverse = []
        self.history_reverse = []
        return 
    end

    def time_interval()
        if token0==token1 then
            return [0,9999999999]
        else
            return [ [realtime[0][:ts],history[0][:ts]].min, [realtime[-1][:ts],history[-1][:ts]].max ]
        end
    end
    
    def data_range()
        if token0==token1 then
            return {realtime:[0,9999999999],history:[0,9999999999]}
        else
            return {realtime:[realtime[0][:ts],realtime[-1][:ts]],history:[history[0][:ts],history[-1][:ts]]}
        end
    end


    def load_from_redis(exchange,token0, token1)
        self.token0 = token0
        self.token1 = token1
        
        if token0==token1 or exchange=="dummy" then
            self.realtime = []
            self.history = []
            self.realtime_reverse = []
            self.history_reverse = []
            return
        else    
            pair_name = self.token0 + self.token1
            self.realtime = DataStore.get("cex.#{exchange}.#{pair_name}.realtime")
            self.history = DataStore.get("cex.#{exchange}.#{pair_name}.history")
    
            if self.realtime!=nil then
                self.realtime = self.realtime.map { |x|
                    {
                        ts:x["ts"]/1000,
                        price:x["mark_price"]
                    }
                }
                
                self.realtime_reverse = self.realtime.reverse
            else
                $logger.call "[data import error] - cex.#{exchange}.#{pair_name}.realtime"
            end
            
            if self.history!=nil then
                self.history = self.history.map { |x|
                    {
                        ts:x["open_time"]/1000,
                        price:x["open_price"]
                    }
                }
                
                self.history_reverse = self.history.reverse
            else
                $logger.call "[data import error] - cex.#{exchange}.#{pair_name}.history"
            end
            
            
        end
    end
    
    def interpolate(cur,upper,lower,upper_value,lower_value)
        return upper_value if (upper_value-lower_value).abs < 1e8
        return ((cur-lower) / (upper-lower).to_f) * (upper_value-lower_value) + lower_value
    end
    
    def get_swap_by_ts(ts)
        return 1 if token0==token1 
        return 1 if self.history==nil or self.realtime==nil

        history_low = (self.history_reverse.bsearch {|x| x[:ts]<=ts } or {ts:0})
        history_upper = (self.history.bsearch {|x| x[:ts]>=ts } or {ts:0})
        realtime_low = (self.realtime_reverse.bsearch {|x| x[:ts]<=ts } or {ts:0})
        realtime_upper = (self.realtime.bsearch {|x| x[:ts]>=ts } or {ts:0})

        history_low = (history_low[:ts] - ts).abs>120 ? {ts:0} :history_low
        history_upper = (history_upper[:ts] - ts).abs>120 ? {ts:0} :history_upper
        realtime_low = (realtime_low[:ts] - ts).abs>2 ? {ts:0} :realtime_low
        realtime_upper = (realtime_upper[:ts] - ts).abs>2 ? {ts:0} :realtime_upper
        
        if realtime_low[:ts]>0 and realtime_upper[:ts]>0 then
            realtime_price = interpolate(ts,realtime_upper[:ts],realtime_low[:ts],realtime_upper[:price],realtime_low[:price])
            return realtime_price
        end
        
        if history_low[:ts]>0 and history_upper[:ts]>0 then
            history_price = interpolate(ts,history_upper[:ts],history_low[:ts],history_upper[:price],history_low[:price])
            return history_price
        end
        
        return nil
    end


    # def get_swap_by_ts(ts)
    #     return 1 if token0==token1 
    #     return 1 if self.history==nil or self.realtime==nil

    #     history_low = ((self.history.filter {|x| x[:ts]<=ts}[-1]) or {ts:0})
    #     history_upper = ((self.history.filter {|x| x[:ts]>=ts}[0]) or {ts:0})
    #     realtime_low = ((self.realtime.filter {|x| x[:ts]<=ts}[-1]) or {ts:0})
    #     realtime_upper = ((self.realtime.filter {|x| x[:ts]>=ts}[0]) or {ts:0})
        
    #     history_low = (history_low[:ts] - ts).abs>120 ? {ts:0} :history_low
    #     history_upper = (history_upper[:ts] - ts).abs>120 ? {ts:0} :history_upper
    #     realtime_low = (realtime_low[:ts] - ts).abs>2 ? {ts:0} :realtime_low
    #     realtime_upper = (realtime_upper[:ts] - ts).abs>2 ? {ts:0} :realtime_upper
        
    #     if realtime_low[:ts]>0 and realtime_upper[:ts]>0 then
    #         realtime_price = interpolate(ts,realtime_upper[:ts],realtime_low[:ts],realtime_upper[:price],realtime_low[:price])
    #         return realtime_price
    #     end
        
    #     if history_low[:ts]>0 and history_upper[:ts]>0 then
    #         history_price = interpolate(ts,history_upper[:ts],history_low[:ts],history_upper[:price],history_low[:price])
    #         return history_price
    #     end
        
    #     return nil
    # end

end


class SwapPriceCexSynthesis < MappingObject

    def self.task
        return "uniswap/swap_price"
    end

    mapping_accessor :token0base, :token1base, :token0, :token1, :base
    mapping_accessor :price_token0base,:price_token1base,:price_token0token1,:price_time_str, :swap_chart
    mapping_accessor :cur_token0base, :cur_token1base, :cur_token0token1
    
    def time_interval()
        token0_interval = token0base.time_interval
        token1_interval = token1base.time_interval
        time_min = [token0_interval[0],token1_interval[0]].min
        time_max = [token0_interval[1],token1_interval[1]].max
        
        time_min = [token0_interval[0],token1_interval[0]].max if time_min==0
        time_max = [token0_interval[1],token1_interval[1]].min if time_max==9999999999
        return [ time_min , time_max ]
    end

    def change_time(ts)
        swap = swap_chart.filter {|x| x["time"]>ts}[0]
        if swap!=nil then
            self.price_token1base = swap["price_token1base"]
            self.price_token0base = swap["price_token0base"]
            self.price_token0token1 = swap["price_token0token1"]
            self.price_time_str = swap["time_str"]
        end
        # self.price_token1base = get_swap_by_ts(ts,self.token1+self.base)
        # self.price_token0base = get_swap_by_ts(ts,self.token0+self.base)
        # self.price_token0token1 = get_swap_by_ts(ts,self.token0+self.token1)
    end

    def load_from_redis(exchange, token0, token1, base)
        self.token0 = token0
        self.token1 = token1
        self.base = base

        self.token0base = SwapPriceCex.new()
        self.token1base = SwapPriceCex.new()

        self.token0base.load_from_redis(exchange, token0, base)
        self.token1base.load_from_redis(exchange, token1, base)
        
        self.cur_token0base = self.token0+self.base
        self.cur_token1base = self.token1+self.base
        self.cur_token0token1 = self.token0+self.token1
        
    end
    
    def data_size_down(sim)
        self.swap_chart = []
        
        time_interval = sim.swap_price.time_interval
        # time_interval = [1647519652,1647519652+3600*24*60]
        # require 'parallel'

        $logger.call "[#{Time.now}] == begin gen cex swap_chart =="
        # $logger.call time_interval
        # self.swap_chart = (time_interval[0]..time_interval[1]).step(3600*24*3).map.with_index {|ts,i| 
        
        
        self.swap_chart = Parallel.map( (time_interval[0]..time_interval[1]).step(CHART_TIME_INTERVAL).to_a, in_processes: 4) { |ts|
            {
                 time:ts, 
                 time_str:Time.at(ts).to_s[0,19], 
                 price_token0base: get_swap_by_ts(ts,cur_token0base),
                 price_token1base: get_swap_by_ts(ts,cur_token1base),
                 price_token0token1: get_swap_by_ts(ts,cur_token0token1),
            } 
        } 
        $logger.call "[#{Time.now}] == end den cex swap_chart =="
        # $logger.call "self.swap_chart = #{self.swap_chart[0,10]}"
        

        token0base.data_size_down(sim)
        token1base.data_size_down(sim)
    end

    def inverse(t)
        return nil if t==nil
        return 1/t
    end

    def get_swap_by_ts(ts,currency=nil)
        currency=self.cur_token0token1 if currency==nil
        if currency==self.cur_token0token1 then
            token0base_price = self.token0base.get_swap_by_ts(ts)
            token1base_price = self.token1base.get_swap_by_ts(ts)
            return nil if token0base_price==nil or token1base_price==nil
            return token0base_price / token1base_price.to_f
        end
        if currency==self.cur_token0base then
            return self.token0base.get_swap_by_ts(ts)
        end
        if currency==self.cur_token1base then
            return self.token1base.get_swap_by_ts(ts)
        end
        if currency==self.base+self.token0 then
            return inverse(self.token0base.get_swap_by_ts(ts))
        end
        if currency==self.base+self.token1 then
            return inverse(self.token1base.get_swap_by_ts(ts))
        end
        if currency==self.token1+self.token0 then
            return inverse(get_swap_by_ts(ts,self.cur_token0token1))
        end
    end

    def clean_price_chart
        return @price_chart = nil
    end


    def price_chart(sim_time_ts=0,sim_time_end_ts=0)
            # $logger.call "price_chart"
            # $logger.call "sim_time_ts = #{sim_time_ts}"
            # $logger.call "sim_time_end_ts = #{sim_time_end_ts}"
            # $logger.call "self.swap_chart.size = #{self.swap_chart.size}"
            # $logger.call "self.swap_chart.first = #{self.swap_chart.first}"
            return @price_chart if @price_chart 
            title = "CEX Price"
            
            # data = swap.map.with_index {|x,i| {x:i, time:x[:time], time_str:Time.at(x[:time]).to_s[0,19], price:x[:price], volume:x[:volume] } }
            data = self.swap_chart
            p1_min_price = data.map {|x| x[:price_token0base]}.filter{|x| x!=nil}.min
            p1_max_price = data.map {|x| x[:price_token0base]}.filter{|x| x!=nil}.max
            p1_min_price = (p1_min_price or 0)*0.7
            p1_max_price = (p1_max_price or 0)*1.3
            p1_title = self.cur_token0base

            p2_min_price = data.map {|x| x[:price_token1base]}.filter{|x| x!=nil}.min
            p2_max_price = data.map {|x| x[:price_token1base]}.filter{|x| x!=nil}.max
            p2_min_price = (p2_min_price or 0)*0.7
            p2_max_price = (p2_max_price or 0)*1.3
            p2_title = self.cur_token1base

            p3_min_price = data.map {|x| x[:price_token0token1]}.filter{|x| x!=nil}.min
            p3_max_price = data.map {|x| x[:price_token0token1]}.filter{|x| x!=nil}.max
            p3_min_price = (p3_min_price or 0)*0.7
            p3_max_price = (p3_max_price or 0)*1.3
            p3_title = self.cur_token0token1

            @price_chart ={
                  "data": {
                    "values": data
                  },
                  "vconcat": [
                        {
                          "title": p1_title,
                          "width": 500,
                          "height": 100,
                          "layer":[
                                {
                                  "mark": {"type": "line", "line": true,"interpolate": "step-after"},
                                  "encoding": {
                                    "x": {"field": "time", "type": "temporal"},
                                    "y": {"field": "price_token0base", "type": "quantitative", "scale": {"domain": [p1_min_price,p1_max_price]} },
                                    "tooltip": [
                                      {"field": "time_str"},
                                      {"field": "price_token0base"}
                                    ]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token0base"}]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_end_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token0base"}]
                                  }
                                }
                          ]
                        },
                        {
                          "title": p2_title,
                          "width": 500,
                          "height": 100,
                          "layer":[
                                {
                                  "mark": {"type": "line", "line": true,"interpolate": "step-after"},
                                  "encoding": {
                                    "x": {"field": "time", "type": "temporal"},
                                    "y": {"field": "price_token1base", "type": "quantitative", "scale": {"domain": [p2_min_price,p2_max_price]} },
                                    "tooltip": [
                                      {"field": "time_str"},
                                      {"field": "price_token1base"}
                                    ]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token1base"}]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_end_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token1base"}]
                                  }
                                }
                             ]
                        },
                        {
                          "title": p3_title,
                          "width": 500,
                          "height": 100,
                          "layer":[
                                {
                                  "mark": {"type": "line", "line": true,"interpolate": "step-after"},
                                  "encoding": {
                                    "x": {"field": "time", "type": "temporal"},
                                    "y": {"field": "price_token0token1", "type": "quantitative", "scale": {"domain": [p3_min_price,p3_max_price]} },
                                    "tooltip": [
                                      {"field": "time_str"},
                                      {"field": "price_token0token1"}
                                    ]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token0token1"}]
                                  }
                                },
                                {
                                  "mark": "rule",
                                  "encoding": {
                                    "x": {
                                      "datum": sim_time_end_ts,
                                      "type": "temporal"
                                    },
                                    "color": {"value": "red"},
                                    "size": {"value": 1},
                                    "tooltip": [{"field": "time_str"}, {"field": "price_token0token1"}]
                                  }
                                }
                          ]
                        }
                  ]
                }        
                
    end
end



def main
    load(Task.load("base/data_store"))

    DataStore.init()

    ethusdt = SwapPriceCex.new
    
    ethusdt.load_from_redis("okex","ETH","USDT")

    $logger.call "token0 = #{ethusdt.token0}"
    $logger.call "token1 = #{ethusdt.token1}"
    $logger.call "realtime = #{ethusdt.realtime[0]}"
    $logger.call "history = #{ethusdt.history[0]}"
    $logger.call "realtime.size = #{ethusdt.realtime.size}"
    $logger.call "history.size = #{ethusdt.history.size}"
    $logger.call "realtime.range: #{Time.at(ethusdt.realtime[0][:ts])} - #{Time.at(ethusdt.realtime[-1][:ts])}"
    $logger.call "history.range: #{Time.at(ethusdt.history[0][:ts])} - #{Time.at(ethusdt.history[-1][:ts])}"

    $logger.call "ETH/USDT"
    time = Time.new(2022,05,17,01,02,03).to_i
    $logger.call " - time=#{time.to_s} price=#{ethusdt.get_swap_by_ts(time)}"

    time = Time.new(2022,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{ethusdt.get_swap_by_ts(time)}"

    time = Time.new(2021,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{ethusdt.get_swap_by_ts(time)}"

    time = Time.new(2023,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{ethusdt.get_swap_by_ts(time)}"

    cex = SwapPriceCexSynthesis.new
    cex.load_from_redis("okex","APE","ETH","USDT")

    $logger.call "APE/ETH"
    time = Time.new(2022,05,17,01,02,03).to_i
    $logger.call " - time=#{time.to_s} price=#{cex.get_swap_by_ts(time)}"

    time = Time.new(2022,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{cex.get_swap_by_ts(time)}"

    time = Time.new(2021,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{cex.get_swap_by_ts(time)}"

    time = Time.new(2023,05,19,01,02,02).to_i
    $logger.call " - time=#{time.to_s} price=#{cex.get_swap_by_ts(time)}"


    time = Time.new(2022,05,19,01,02,02).to_i
    $logger.call cex.get_swap_by_ts(time,"APEETH")
    $logger.call cex.get_swap_by_ts(time,"APEUSDT")
    $logger.call cex.get_swap_by_ts(time,"ETHUSDT")
    $logger.call cex.get_swap_by_ts(time,"ETHAPE")
    $logger.call cex.get_swap_by_ts(time,"USDTAPE")
    $logger.call cex.get_swap_by_ts(time,"USDTETH")
    
    $logger.call " == time_interval =="
    $logger.call cex.time_interval
    $logger.call cex.token0base.time_interval
    $logger.call cex.token1base.time_interval


    $logger.call " == data_range =="

    $logger.call cex.token0base.data_range    
    $logger.call cex.token1base.data_range    

    $logger.call " == data_size_down =="
    cex.data_size_down(nil)
end