__TASK_NAME__ = "uniswap/dex_v3"

load(Task.load("base/render_wrap"))

class Dex < MappingObject
    def self.task
        return "uniswap/dex_v3"
    end
    
    mapping_accessor :swap, :time_table, :swap_chart
    
    def count
        self.swap.count
    end
    
    # time_id to "2022-02-02 02:02:02" format    
    def time_str(time)
        return Time.at(self.time_table[time]).utc.to_s[0,19] if self.time_table[time]
        time.to_s
    end
    
    # time_id to "2022-02-02T02:02" format    
    def time_str_widget(time)
        str = time_str(time)
        str[0,16].gsub(/ /,"T")
    end

    # str "2022-02-02T02:02" to time_id
    def find_time(str)
        arr = str.gsub(/T/,"-").gsub(/:/,"-").split("-")
        time = Time.utc(arr[0],arr[1],arr[2],arr[3],arr[4]).to_i
        ret = nil
        self.time_table.each_with_index {|x,i|
            if x >= time then 
                ret=i; 
                break; 
            end 
        }
        return ret

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
end