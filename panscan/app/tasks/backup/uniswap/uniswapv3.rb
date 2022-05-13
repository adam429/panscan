__TASK_NAME__ = "uniswap/uniswapv3"

load(Task.load("base/render_wrap"))



class UniswapV3 < MappingObject
    mapping_accessor :liquidity_pool, :price, :token0, :token1, :token0_decimal, :token1_decimal, :rate
    
    def number(num)
        # BigDecimal(num,Float::DIG)
        num.to_f
    end
    
    def initialize
        super()
    end
    
    def init(token0, token1, token0_decimal, token1_decimal, price, rate)
        self.token0 = token0
        self.token1 = token1
        self.token0_decimal = number(token0_decimal)
        self.token1_decimal = number(token1_decimal)
        self.liquidity_pool = []
        self.price = number(price)
        self.rate = number(rate)
    end
    
    def inspect
        $logger.call "token: #{self.data[:token0]}/#{self.data[:token1]} #{price}"
    end
    
    def p2adjp(price)
        price = number(price)
        price*10**(self.token1_decimal-self.token0_decimal)
    end
    
    def adjp2p(adj_price)
        adj_price = number(adj_price)
        adj_price*10**(self.token0_decimal-self.token1_decimal)
    end
    
    def d2adjd(value,decimal)
        value = number(value)
        value*10**decimal
    end
    
    def adjd2d(value,decimal)
        value = number(value)
        value*10**(-decimal)
    end    
    
    def adj_xy2lp(x,y,l,price)
        l=number(l)
        x=number(x)
        y=number(y)
        price=number(price)
        
        price_a = (Math.sqrt(price)-y/l)**2
        price_b = (1/(1/Math.sqrt(price) - x/l))**2
        
        return price_a, price_b
    end
    
    def lp2xy(l,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        l = number(l)
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        x = l * (Math.sqrt(price_b)-Math.sqrt(price))/Math.sqrt(price*price_b)
        y = l * (Math.sqrt(price) - Math.sqrt(price_a))
        x=adjd2d(x,self.token0_decimal)
        y=adjd2d(y,self.token1_decimal)
        return x,y
    end
    
    def lp2dxdy(l,price,new_price,price_a,price_b)
        # price = p2adjp(price)
        # new_price = p2adjp(new_price)
        # price_a = p2adjp(price_a)
        # price_b = p2adjp(price_b)
        dx = l2x(l,new_price,price_a,price_b) - l2x(l,price,price_a,price_b)
        dy = l2y(l,new_price,price_a,price_b) - l2y(l,price,price_a,price_b)
        # dx=adjd2d(dx,self.token0_decimal)
        # dy=adjd2d(dy,self.token1_decimal)

        # $logger.call "[lp2dxdy] #{l} #{price} #{new_price} #{price_a} #{price_b} #{dx} #{dy}"
        return dx,dy
    end        
    
    def dx2p(dx,l,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        l = number(l)
        dx = number(dx)
        
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        dx = d2adjd(dx,self.token0_decimal)
        new_price = (1/(dx/l + 1/Math.sqrt(price)))**2
        new_price = adjp2p(new_price)
        return new_price
    end        

    def dy2p(dy,l,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        l = number(l)
        dy = number(dy)
        
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        dy = d2adjd(dy,self.token1_decimal)
        new_price = (dy/l+Math.sqrt(price))**2        
        new_price = adjp2p(new_price)
        return new_price
    end        


    def x2l(x,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        x = number(x)

        x = d2adjd(x,self.token0_decimal)
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        x * Math.sqrt(price * price_b) / (Math.sqrt(price_b) - Math.sqrt(price))
    end

    def y2l(y,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        y = number(y)
        
        y = d2adjd(y,self.token1_decimal)
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        y / (Math.sqrt(price) - Math.sqrt(price_a))
    end
    
    def l2y(l,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        l = number(l)
        
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        y = l * (Math.sqrt(price) - Math.sqrt(price_a))
        y=adjd2d(y,self.token1_decimal)
    end
    
    def l2x(l,price,price_a,price_b)
        price = number(price)
        price_a = number(price_a)
        price_b = number(price_b)
        l = number(l)
        
        price = p2adjp(price)
        price_a = p2adjp(price_a)
        price_b = p2adjp(price_b)
        x = l / (Math.sqrt(price * price_b)  / (Math.sqrt(price_b) - Math.sqrt(price)))    
        x=adjd2d(x,self.token0_decimal)
    end
    
    def calc_add_liquidity_ratio(price_a,price_b)
        x = 100
        l = x2l(x,price,price_a,price_b)
        y = l2y(l,price,price_a,price_b)
        #$logger.call "[calc_add_liquidity_ratio] (#{price_a},#{price_b})=[#{x},#{y},#{l}}]"
        return [x,y,l]
    end
    
    def add_liquidity(x,y,price_a,price_b,sender=nil,run=true)
        # $logger.call x
        # $logger.call y
        # $logger.call price_a
        # $logger.call price_b
        # $logger.call price

        if price_a <= price and price <= price_b then
        
            # ex,ey = calc_add_liquidity_ratio(price_a,price_b)
            
            l_x = x2l(x,price,price_a,price_b)
            l_y = y2l(y,price,price_a,price_b)
            l = [l_x,l_y].min
            
            ret_x = x - l2x(l,price,price_a,price_b)
            ret_y = y - l2y(l,price,price_a,price_b)
        end
        
        if price < price_a then
            l = l_x = x2l(x,price_a,price_a,price_b)
            ret_y = ret_x = 0            
        end

        if price_b < price then
            l = l_y = y2l(y,price_b,price_a,price_b)
            ret_y = ret_x = 0            
        end

        self.liquidity_pool.push( {price_a:price_a,price_b:price_b,l:l,sender:sender,token0_fee:0,token1_fee:0}) if run and l>0
        #$logger.call "[add_liquidity] l = #{l} | ret_x = #{ret_x} | ret_y = #{ret_y}"
        return ret_x,ret_y

    end
    
    def remove_liquidity(x,y,price_a,price_b,sender=nil,run=true)
        if price_a <= price and price <= price_b then
        
            # ex,ey = calc_add_liquidity_ratio(price_a,price_b)
            
            l_x = x2l(x,price,price_a,price_b)
            l_y = y2l(y,price,price_a,price_b)
            l = [l_x,l_y].min
            
            ret_x = x - l2x(l,price,price_a,price_b)
            ret_y = y - l2y(l,price,price_a,price_b)
        end
        
        if price < price_a then
            l = l_x = x2l(x,price_a,price_a,price_b)
            ret_y = ret_x = 0            
        end

        if price_b < price then
            l = l_y = y2l(y,price_b,price_a,price_b)
            ret_y = ret_x = 0            
        end

        self.liquidity_pool.push( {price_a:price_a,price_b:price_b,l:-l,sender:sender,token0_fee:0,token1_fee:0}) if run and l>0
        #$logger.call "[add_liquidity] l = #{l} | ret_x = #{ret_x} | ret_y = #{ret_y}"
        return ret_x,ret_y
    end
    
    def slice_liquidity_pool(user="user")

        edge = liquidity_pool.map {|x| [x[:price_a],x[:price_b]] }.flatten.uniq.sort
        edge = (0..edge.size-2).map.with_index {|x,i|
            lower_price = edge[x]
            upper_price = edge[x+1]
            sub_pool = liquidity_pool.filter {|pool| pool[:price_a]<= lower_price and upper_price <=pool[:price_b] }
            total_liquidity = sub_pool.map {|x| x[:l]}.sum
            user_liquidity = sub_pool.filter {|pool| pool[:sender]==user }.map {|x| x[:l]}.sum
            {id:i, price_a:lower_price,price_b:upper_price,l:total_liquidity,ul:user_liquidity}
        }
        
        # todo pool_mapping
        user_pool = -1
        (0..liquidity_pool.size-1).each do |i|
            if liquidity_pool[i][:sender]==user then
                user_pool = i
                break
            end
        end
        pool_mapping = edge.map {|x| x[:ul]>0 ? user_pool : -1 }
        
        # $logger.call "edge = #{edge}"
        # $logger.call "pool_mapping = #{pool_mapping}"
        
        return edge,pool_mapping
    end
    
    def update_lp_token
        change_price(self.price)
    end
    
    def change_price(new_price,volume0=0,volume1=0,run=false)
        #$logger.call "new_price = #{new_price} volume0 = #{volume0} volume1 = #{volume1}"
                
        if run then
            # volume to fee
            slice_pool,pool_mapping = self.slice_liquidity_pool()
            pool_index = find_pool(slice_pool,price)
            pool = slice_pool[pool_index]
            l = pool[:l]
            ul = pool[:ul]
    
            volume0 = volume0 / 2.to_f
            volume1 = volume1 / 2.to_f
            feex = volume0 * self.rate
            feey = volume1 * self.rate
            
            distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
            
            
            
            # change fee
            
            # if new_price > self.price then
            #     # direction => higher price
            #     loop do
            #         # $logger.call "#{pool_index} - #{pool.to_s}"
            #         price_a = pool[:price_a]
            #         price_b = pool[:price_b]
            #         l = pool[:l]
            #         ul = pool[:ul]
                    
            #         if new_price > price_b then
            #             # over the pool
            #             next_price = price_b
            #             max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
            #             feey = max_dy / (1-self.rate) * self.rate
            #             feex = 0
            #             # $logger.call "[over pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
            #             distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                        
            #             pool_index = pool_index + 1
            #             break if pool_index>=slice_pool.size
            #             pool = slice_pool[pool_index]
            #         else
            #             # within the pool
            #             next_price = new_price
            #             max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
            #             feey = max_dy / (1-self.rate) * self.rate
            #             feex = 0
            #             # $logger.call "[within pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
            #             distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                        
            #             break
            #         end
            #     end
            # end
            
            # if new_price < self.price then
            #     # direction => low price
            #     loop do
            #         $logger.call "#{pool_index} - #{pool.to_s}"
            #         price_a = pool[:price_a]
            #         price_b = pool[:price_b]
            #         l = pool[:l]
            #         ul = pool[:ul]
                    
            #         if new_price < price_a then
            #             # over the pool
            #             next_price = price_a
            #             max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
            #             feey = 0
            #             feex = max_dx / (1-self.rate) * self.rate
            #             $logger.call "[over pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
            #             distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                        
            #             pool_index = pool_index - 1
            #             break if pool_index<0
            #             pool = slice_pool[pool_index]
            #         else
            #             # within the pool
            #             next_price = new_price
            #             max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
            #             feey = 0
            #             feex = max_dx / (1-self.rate) * self.rate
            #             $logger.call "[within pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
            #             distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                        
            #             break
            #         end
            #     end
            # end
        end
            
            
        self.price = new_price

        # change token0 token1 assets
        self.liquidity_pool.map! do |pool|
            if pool[:sender]!=nil then
                price_a = pool[:price_a].to_f
                price_b = pool[:price_b].to_f
                price = $data['uni'].price.to_f
                
                if price<price_a then
                    price = price_a
                end
                if price>price_b then
                    price = price_b
                end
                vx,vy = $data['uni'].lp2xy(pool[:l],price,price_a,price_b)
                pool[:token0]=vx.to_f
                pool[:token1]=vy.to_f
            end
            pool
        end
    end
    
    def clean_liquidity_chart
        @liquidity_chart = nil
    end
    
    def liquidity_chart(add_lower,add_upper,swap_price=nil,swap_l=nil)
        return @liquidity_chart if @liquidity_chart
        if @liquidity_chart==nil then
        
        
        pool,pool_maping = slice_liquidity_pool
        # add_lower -= 0.0001
        # add_upper += 0.0001
        # price = self.price + 0.0001



        data = (-3000..3000).map { |x| 
            lower_price = price*(1.001**x)
            upper_price = price*(1.001**(x+1))
            min_price = (lower_price+upper_price)/2
            value = pool.filter {|x| x[:price_a]<=lower_price and upper_price<=x[:price_b]}[0]
            
            {"price":min_price,"value":value[:l],"user_value":value[:ul]} if value             
        }.filter {|x| x!=nil}
        
        
        # $logger.call "swap_price = #{swap_price}  swap_l = #{swap_l}"
        data.push({"price":swap_price, "value":swap_l, "swap":true}) if swap_price!=nil and swap_price>0
        
        @liquidity_chart = spec = 
{
  "title": "Liquidity Pool",
  "width": 600,
  "height": 200,
  "data": {
    "values": data
  },
  "layer": [
    {
      "transform": [{"filter": "datum.swap != true"}],
      "mark": "bar",
      "encoding": {
        "x": {"field": "price", "type": "nominal", "axis": {"labels": false}},
        "y": {"field": "value", "type": "quantitative"},
        "tooltip": [
          {"field": "price"},
          {"field": "value"},
          {"field": "user_value"}
        ]
      }
    },
    {
      "transform": [{"filter": "datum.swap != true"}],
      "mark": {"type": "bar", "color": "#f58518"},
      "encoding": {
        "x": {"field": "price", "type": "nominal", "axis": {"labels": false}},
        "y": {"field": "user_value", "type": "quantitative"}
      }
    },
    {
      "mark": "rule",
      "encoding": {
        "x": {"datum": add_lower,"type": "nominal"},
        "color": {"value": "blue"},
        "size": {"value": 1},
      }
    },
    {
      "mark": "rule",
      "encoding": {
        "x": {"datum": add_upper,"type": "nominal"},
        "color": {"value": "blue"},
        "size": {"value": 1},
      }
    },
    {
      "mark": "rule",
      "encoding": {
        "x": {"datum": price,"type": "nominal"},
        "color": {"value": "lightgrey"},
        "size": {"value": 1},
      }
    },
    {
      "transform": [{"filter": "datum.swap == true"}],
      "mark": {
        "type": "point",
        "size": 30,
        "color": "red",
        "shape": "diamond"
      },
      "encoding": {
        "x": {"field": "price", "type": "nominal"},
        "y": {"field": "value", "type": "quantitative"},
        "tooltip": [{"field": "price"}, {"field": "value"}]
      }
    }
  ]
}
    end
    end
    
    def clean_binding_curve
        @binding_curve = nil
    end

    def binding_curve_p2xy(pool,price)
        # $logger.call "#{pool} - #{price}"
        value = pool.filter {|x| x[:price_a]<=price and price<=x[:price_b]}[0]
        if value then
          l = value[:l]
          price_a = value[:price_a]
          price_b = value[:price_b]
          x,y = lp2xy(l,price,price_a,price_b)
          x=x+l/Math.sqrt(price_b)
          y=y+l*Math.sqrt(price_a)
          
          return adjd2d(x,token0_decimal),adjd2d(y,token0_decimal),value[:id]
        else
          return nil,nil,nil
        end        
    end
    
    def binding_curve(add_lower,add_upper,swap_price=nil,swap_l=nil)
        return @binding_curve if @binding_curve
        
        pool,pool_mapping = slice_liquidity_pool
        add_lower
        add_upper
        price = self.price 

        data = (-300..300).map { |x| 
            lower_price = price*(1.01**x)
            upper_price = price*(1.01**(x+1))
            mid_price = (lower_price+upper_price)/2
            x,y,id = binding_curve_p2xy(pool,mid_price)
            {"pool":id, "x":x.to_f,"y":y.to_f} if id!=nil
        }.filter {|x| x!=nil}
        
        (0..pool.size-2).each do |i|
            # $logger.call "#{i} - #{pool[i]} - #{pool[i+1]}"
            x,y,id = binding_curve_p2xy(pool,pool[i][:price_b]-0.001)
            data.push({"x":x.to_f, "y":y.to_f, "pool":pool.size+i}) if id!=nil

            x,y,id = binding_curve_p2xy(pool,pool[i+1][:price_a]+0.001)
            data.push({"x":x.to_f, "y":y.to_f, "pool":pool.size+i}) if id!=nil
        end

        # add_lower
        x,y,id = binding_curve_p2xy(pool,add_lower)
        data.push({"x":x.to_f, "y":y.to_f, "add_lower":true}) if id!=nil
        data.push({"x":0, "y":0, "add_lower":true}) 

        # add_upper
        x,y,id = binding_curve_p2xy(pool,add_upper)
        data.push({"x":x.to_f, "y":y.to_f, "add_upper":true}) if id!=nil
        data.push({"x":0, "y":0, "add_upper":true}) 
        
        # cur_price
        x,y,id = binding_curve_p2xy(pool,price)
        data.push({"x":x.to_f, "y":y.to_f, "cur":true}) if id!=nil
        data.push({"x":0, "y":0, "cur":true}) 
    
        # swap_price
        x,y,id = binding_curve_p2xy(pool,swap_price)
        data.push({"x":x.to_f, "y":y.to_f, "swap":true}) if id!=nil and swap_price!=nil and swap_price>0
        spec = 
{
  "title": "Binding Curve",
  "width": 200,
  "height": 200,
  "data": {
    "values": data
  },
  "layer": [
    {
      "transform": [{"filter": "datum.add_lower == true"}],
      "mark": {"type": "line", "color": "blue"},
      "encoding": {
        "x": {"field": "x", "type": "quantitative"},
        "y": {"field": "y", "type": "quantitative"},
        "tooltip": [{"field": "x"}, {"field": "y"}]
      }
    },
    {
      "transform": [{"filter": "datum.add_upper == true"}],
      "mark": {"type": "line", "color": "blue"},
      "encoding": {
        "x": {"field": "x", "type": "quantitative"},
        "y": {"field": "y", "type": "quantitative"},
        "tooltip": [{"field": "x"}, {"field": "y"}]
      }
    },
    {
      "transform": [{"filter": "datum.cur == true"}],
      "mark": {"type": "line", "color": "lightgrey"},
      "encoding": {
        "x": {"field": "x", "type": "quantitative"},
        "y": {"field": "y", "type": "quantitative"},
        "tooltip": [{"field": "x"}, {"field": "y"}]
      }
    },
    {
      "transform": [{"filter": "datum.swap == true"}],
      "mark": {
        "type": "point",
        "size": 30,
        "color": "red",
        "shape": "diamond"
      },
      "encoding": {
        "x": {"field": "x", "type": "quantitative"},
        "y": {"field": "y", "type": "quantitative"},
        "tooltip": [{"field": "x"}, {"field": "y"}]
      }
    }
  ]
}
    (0..pool.size*2).each do |i|
        spec["layer"].push({
          "transform": [{"filter": "datum.pool == #{i}"}],
          "mark": {"type": "line", "interpolate": "monotone"},
          "encoding": {
            "x": {"field": "x", "type": "quantitative"},
            "y": {"field": "y", "type": "quantitative"},
            "tooltip": [{"field": "x"}, {"field": "y"}]
          }
        })
    end
    
    @binding_curve = spec

    end
    
    def find_pool(slice_pool,price)
        slice_pool.filter_map.with_index {|x,i| i if x[:price_a]<=price and price<=x[:price_b]}[0]
    end
    
    def distribute_fee(pool_index,feex,feey,l,ul)
        return if pool_index<0
        #$logger.call "distribute fee #{self.liquidity_pool[pool_index]} #{feex} #{feey} #{l} #{ul}"
        if self.liquidity_pool[pool_index][:sender]!=nil then
            self.liquidity_pool[pool_index][:token0_fee] = self.liquidity_pool[pool_index][:token0_fee] + feex*ul/l
            self.liquidity_pool[pool_index][:token1_fee] = self.liquidity_pool[pool_index][:token1_fee] + feey*ul/l
        end
    end
    
    def swap(x,y,run=true)
        price = self.price
        ret_x = x
        ret_y = y
        
        $logger.call "[swap] x=#{ret_x} y=#{ret_y} price=#{price}"
        if ret_x==0 then
            # direction => higher price
            
            slice_pool,pool_mapping = self.slice_liquidity_pool()
            pool_index = find_pool(slice_pool,price)
            pool = slice_pool[pool_index]
            
            loop do
                # $logger.call "#{pool_index} - #{pool.to_s}"
                price_a = pool[:price_a]
                price_b = pool[:price_b]
                l = pool[:l]
                ul = pool[:ul]
                new_price = price_b
                
                max_dx, max_dy = lp2dxdy(l,price,new_price,price_a,price_b)
                #$logger.call "[swap slice_pool] price_a=#{price_a} price_b=#{price_b} l=#{l} price=#{price} new_price=#{new_price} max_dx=#{max_dx} max_dy=#{max_dy}"
                
                if max_dy < ret_y * (1-self.rate) then
                    # over pool
                    feey = max_dy * self.rate
                    feex = 0
                    distribute_fee(pool_mapping[pool_index],feex,feey,l,ul) if run
                    
                    dy = max_dy - feey
                    dx = max_dx
                    ret_x -= (dx+feex)
                    ret_y -= (dy+feey)
                    
                    price = new_price = pool[:price_b]
                    self.price = new_price if run

                    pool_index = pool_index + 1
                    return ret_x, ret_y, new_price,l if pool_index>=slice_pool.size
                    pool = slice_pool[pool_index]
                else
                    # current pool slice is enough
                    feey = ret_y * self.rate
                    feex = 0
                    distribute_fee(pool_mapping[pool_index],feex,feey,l,ul) if run

                    dy = ret_y - feey
                    new_price = dy2p(dy,l,price,price_a,price_b) 
                    dx,_ = lp2dxdy(l,price,new_price,price_a,price_b)
                    
                    ret_x -= (dx+feex)
                    ret_y -= (dy+feey)
                    
                    price = new_price

                    self.price = new_price if run
                    #$logger.call "[swap return] ret_x=#{ret_x} ret_y=#{ret_y} dx=#{dx} dy=#{dy}  feex=#{feex} feey=#{feey} price=#{price} l=#{l}"
                    return ret_x, ret_y, new_price, l
                end
            end
        end

        if ret_y==0 then
            # direction => lower price
            slice_pool,pool_mapping = self.slice_liquidity_pool()
            pool_index = find_pool(slice_pool,price)
            pool = slice_pool[pool_index]
            
            loop do
                # $logger.call "#{pool_index} - #{pool.to_s}"
                price_a = pool[:price_a]
                price_b = pool[:price_b]
                l = pool[:l]
                ul = pool[:ul]
                new_price = price_a
                
                max_dx, max_dy = lp2dxdy(l,price,new_price,price_a,price_b)
                #$logger.call "[swap slice_pool] price_a=#{price_a} price_b=#{price_b} l=#{l} price=#{price} new_price=#{new_price} max_dx=#{max_dx} max_dy=#{max_dy}"
                
                if max_dx<ret_x * (1-self.rate) then
                    # over pool
                    feey = 0
                    feex = max_dx * self.rate
                    distribute_fee(pool_mapping[pool_index],feex,feey,l,ul) if run
                    
                    dy = max_dy
                    dx = max_dx - feex
                    ret_x -= (dx+feex)
                    ret_y -= (dy+feey)
                    
                    price = new_price = pool[:price_a]
                    self.price = new_price if run
                    
                    pool_index = pool_index - 1
                    return ret_x, ret_y, new_price,l  if pool_index<0
                    pool = slice_pool[pool_index]
                else
                    # current pool slice is enough
                    feey = 0
                    feex = ret_x * self.rate
                    distribute_fee(pool_mapping[pool_index],feex,feey,l,ul) if run

                    dx = ret_x - feex
                    new_price = dx2p(dx,l,price,price_a,price_b) 
                    _,dy = lp2dxdy(l,price,new_price,price_a,price_b)
                    
                    ret_x -= (dx+feex)
                    ret_y -= (dy+feey)
                    
                    price = new_price

                    self.price = new_price if run
                    #$logger.call "[swap return] ret_x=#{ret_x} ret_y=#{ret_y} dx=#{dx} dy=#{dy}  feex=#{feex} feey=#{feey} price=#{price} l=#{l}"
                    return ret_x, ret_y, new_price,l
                end
            end
        end
        
        return ret_x,ret_y,price,l

    end
    
end
