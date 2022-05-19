__TASK_NAME__ = "uniswap/swap_price"

load(Task.load("base/render_wrap"))

class TimeTable < MappingObject
    def self.task
        return "uniswap/swap_price"
    end

    mapping_accessor :time_table
    
    def load_from_redis(pool_id,uni,reversed=false)
        swap =  DataStore.get("uniswap.#{pool_id}.swap")

        block_to_time = DataStore.get("uniswap.#{pool_id}.time_table")
        block_to_time = block_to_time.map {|x,y,z|  [x,[y,z]] }.to_h
        
        self.time_table = swap.map {|x| (block_to_time[x[:block_number]] or [0])[0] }
            
    end
    
    def count
        self.time_table.count
    end
    
    # time_id to "2022-02-02 02:02:02" format    
    def time_str_by_id(id)
        return Time.at(self.time_table[id]).utc.to_s[0,19] if self.time_table[id]
        time.to_s
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
    
    # look up time_table
    def find_ts_by_id(id)
        self.time_table[id]
    end
    
    def find_id_by_ts(ts)
        ret = nil
        self.time_table.each_with_index {|x,i|
            if x >= ts then 
                ret=i; 
                break; 
            end 
        }
        ret = self.time_table.size-1 if ret==nil
        return ret
    end

end

class SwapPriceBase < MappingObject
    def self.task
        return "uniswap/swap_price"
    end
    
    mapping_accessor :swap, :swap_chart, :time_table
    

    def get_swap_by_id(id)
        return self.swap[id]
    end
    
    def get_swap_by_ts(ts)
        ret = nil
        self.time_table.each_with_index {|x,i|
            if x >= ts then 
                ret=i; 
                break; 
            end 
        }
        ret = self.time_table.size-1 if ret==nil
        return self.swap[ret]
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
    mapping_accessor :realtime, :history

    def load_from_redis(exchange,token0, token1)
        self.token0 = token0
        self.token1 = token1

        pair_name = self.token0 + self.token1
        self.realtime = DataStore.get("cex.#{exchange}.#{pair_name}.realtime")
        self.history = DataStore.get("cex.#{exchange}.#{pair_name}.history")

        self.realtime = self.realtime.map { |x|
            {
                ts:x["ts"]/1000,
                price:x["mark_price"]
            }
        }
        
        self.history = self.history.map { |x|
            {
                ts:x["open_time"]/1000,
                price:x["open_price"]
            }
        }
    end
    
    def interpolate(cur,upper,lower,upper_value,lower_value)
        return upper_value if (upper_value-lower_value).abs < 1e8
        return ((cur-lower) / (upper-lower).to_f) * (upper_value-lower_value) + lower_value
    end

    def get_swap_by_ts(ts)
        history_low = ((self.history.filter {|x| x[:ts]<=ts}[-1]) or {ts:0})
        history_upper = ((self.history.filter {|x| x[:ts]>=ts}[0]) or {ts:0})
        realtime_low = ((self.realtime.filter {|x| x[:ts]<=ts}[-1]) or {ts:0})
        realtime_upper = ((self.realtime.filter {|x| x[:ts]>=ts}[0]) or {ts:0})
        
        history_low = (history_low[:ts] - ts).abs>120 ? {ts:0} :history_low
        history_upper = (history_upper[:ts] - ts).abs>120 ? {ts:0} :history_upper
        realtime_low = (realtime_low[:ts] - ts).abs>2 ? {ts:0} :realtime_low
        realtime_upper = (realtime_upper[:ts] - ts).abs>2 ? {ts:0} :realtime_upper
        
        # $logger.call ts
        # $logger.call history_low
        # $logger.call history_upper
        # $logger.call realtime_low
        # $logger.call realtime_upper
        
        if realtime_low[:ts]>0 and realtime_upper[:ts]>0 then
            realtime_price = interpolate(ts,realtime_upper[:ts],realtime_low[:ts],realtime_upper[:price],realtime_low[:price])
            return {price:realtime_price}
        end
        
        if history_low[:ts]>0 and history_upper[:ts]>0 then
            history_price = interpolate(ts,history_upper[:ts],history_low[:ts],history_upper[:price],history_low[:price])
            return {price:history_price}
        end
        
        return {price:nil}
    end
    
end


class SwapPriceCexSynthesis < MappingObject
    mapping_accessor :token0base, :token1base, :token0, :token1, :base

    def load_from_redis(exchange, token0, token1, base)
        self.token0 = token0
        self.token1 = token1
        self.base = base

        self.token0base = SwapPriceCex.new()
        self.token1base = SwapPriceCex.new()

        self.token0base.load_from_redis(exchange, token0, base)
        self.token1base.load_from_redis(exchange, token1, base)
    end

    def get_swap_by_ts(ts,currency=nil)
        if currency then
        else
            return {price: self.token0base.get_swap_by_ts(ts)[:price] / self.token1base.get_swap_by_ts(ts)[:price].to_f}
        end
    end

end


load(Task.load("base/data_store"))

def main
    DataStore.init()

    # ethusdt = SwapPriceCex.new
    
    # ethusdt.load_from_redis("okex","ETH","USDT")

    # $logger.call ethusdt.token0
    # $logger.call ethusdt.token1
    # $logger.call ethusdt.realtime[0]
    # $logger.call ethusdt.history[0]
    # $logger.call ethusdt.realtime.size
    # $logger.call ethusdt.history.size
    # $logger.call "realtime: #{Time.at(ethusdt.realtime[0][:ts])} - #{Time.at(ethusdt.realtime[-1][:ts])}"
    # $logger.call "history: #{Time.at(ethusdt.history[0][:ts])} - #{Time.at(ethusdt.history[-1][:ts])}"


    # time = Time.new(2022,05,17,01,02,03).to_i
    # $logger.call ethusdt.get_swap_by_ts(time)

    # time = Time.new(2022,05,19,01,02,02).to_i
    # $logger.call ethusdt.get_swap_by_ts(time)

    # time = Time.new(2021,05,19,01,02,02).to_i
    # $logger.call ethusdt.get_swap_by_ts(time)

    # time = Time.new(2023,05,19,01,02,02).to_i
    # $logger.call ethusdt.get_swap_by_ts(time)

    cex = SwapPriceCexSynthesis.new
    cex.load_from_redis("okex","APE","ETH","USDT")

    time = Time.new(2022,05,17,01,02,03).to_i
    $logger.call cex.get_swap_by_ts(time)

    time = Time.new(2022,05,19,01,02,02).to_i
    $logger.call cex.get_swap_by_ts(time)

    time = Time.new(2021,05,19,01,02,02).to_i
    $logger.call cex.get_swap_by_ts(time)

    time = Time.new(2023,05,19,01,02,02).to_i
    $logger.call cex.get_swap_by_ts(time)

end