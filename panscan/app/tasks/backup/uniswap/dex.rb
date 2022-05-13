__TASK_NAME__ = "uniswap/dex"

load(Task.load("base/render_wrap"))

class Dex < MappingObject
    mapping_accessor :price, :volume, :time_table
    
    def count
        self.price.count
    end

    def clean_price_volume_chart
        @price_volume_chart = nil
    end
    
    def price_volume_chart(price_a=nil,price_b=nil,cur_price=nil,sim_time=nil)
            title = "Price & Volume"
    
            price_data = price.reverse.map.with_index {|x,i| {x:i, time:x[:time], time_str:x[:time][0,13], price:x[:close] } }
            
            min_price = price_data.map {|x| x[:price]}.min
            max_price = price_data.map {|x| x[:price]}.max
            min_price = min_price*0.7
            max_price = max_price*1.3

            volume_data = volume.reverse.map.with_index {|x,i| {x:i, time:x[:time], time_str:x[:time][0,13], volume:x[:volumeToken1] } }

            data=[]
            (0..price_data.count-1).each do |i|
                data.push({x:price_data[i][:x], time:price_data[i][:time], time_str:price_data[i][:time_str], price:price_data[i][:price], volume:volume_data[i][:volume]  })
            end

            @price_volume_chart ={
                  "title": title,
                  "data": {
                    "values": data
                  },
                  "vconcat": [
                      {
                          "width": 600,
                          "height": 200,
                          "layer":[
                                {
                                  "mark": {
                                    "type": "line",
                                    "line": true
                                  },
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
                                      "datum": self.time_table[sim_time][:time_value],
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
                          "width": 600,
                          "height": 200,
                          "layer":[
                              {
                                  "mark": {
                                    "type": "area",
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
                                  "datum": self.time_table[sim_time][:time_value],
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
    
    def price_in_range(price_a, price_b, hour)
        price[0,hour].filter {|x| price_a <= x[:close] and x[:close] <= price_b }.count / hour.to_f
    end
    
    def price_in_range_from(price_a, price_b, from)
        select_price = price[from,price.size]
        select_price.filter {|x| price_a <= x[:close] and x[:close] <= price_b }.count / select_price.count.to_f
    end
    
    def price_range(hour)
        data = price[0,hour].map{|x| x[:close] }
        return data.min, data.max
    end
end