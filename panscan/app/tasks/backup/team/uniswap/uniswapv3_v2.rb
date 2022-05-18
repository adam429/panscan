__TASK_NAME__ = "team/uniswap/uniswapv3_v2"

load(Task.load("base/render_wrap"))

class UniswapV3 < MappingObject
    def self.task
        return "team/uniswap/uniswapv3_v2"
    end
end

class Pool< MappingObject
    def self.task
        return "team/uniswap/uniswapv3_v2"
    end
    
    mapping_accessor :init_tick,:pool,:swap, :block_number
    mapping_accessor :cur_blocknumber, :cur_liquidity_pool, :cur_price, :swap_p, :pool_p


    def initialize()
        super()
    end
    
    def clean_liquidity(sender=nil)
        self.cur_liquidity_pool = self.cur_liquidity_pool.filter {|x| x[:sender]!=sender }
    end

    def clean_fee(sender=nil)
        self.cur_liquidity_pool = self.cur_liquidity_pool.map {|x| x[:token0_fee]=0; x[:token1_fee]=0; x}
    end
    
    
    def init(_pool=[],_init_tick=nil,_swap=[])
        puts "_pool=#{_pool}"
        puts "_init_tick=#{_init_tick}"
        puts "_swap=#{_swap}"
        self.pool = _pool
        self.init_tick = _init_tick
        self.swap = _swap
        self.block_number = 0
        self.reset
    end

    def number(n)
        n.to_f
    end

    def reset(user_pool=[])
        puts "call reset user_pool=#{user_pool}"
        self.cur_blocknumber = 0
        self.cur_liquidity_pool = user_pool
        self.cur_price = 1.0001**self.init_tick if self.init_tick
        self.swap_p = 0
        self.pool_p = 0
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

    # input block_number
    # calc lp to block_number time
    def calc_pool(block_number,user_pool=[])
        $logger.call "call calc_pool #{block_number} #{user_pool}"
        block_number = 9999999999 if block_number==-1
        
        return self.cur_liquidity_pool if block_number==self.cur_blocknumber 
        if block_number<self.cur_blocknumber then
            self.reset(user_pool)
            return calc_pool(block_number)
        end
        if block_number>self.cur_blocknumber then
            _swap = swap.to_a
            _pool = pool
            
            sid = nil
            pid = nil
            
            turn = 0
            loop do
                turn += 1
                puts "loop turn=#{turn}"
                
                if self.swap_p==_swap.size and self.pool_p==_pool.size then
                    break
                end

                sid = _swap[self.swap_p]==nil ? 999_999_999_999_999 : _swap[self.swap_p][:id]
                pid = _pool[self.pool_p]==nil ? 999_999_999_999_999 : _pool[self.pool_p][:id]

                if sid<=pid then
                # do swap
                    if _swap[self.swap_p][:block_number]>block_number then
                        self.swap_p = _swap.size
                        next
                    end
            
                    self.cur_price = 1.0001**_swap[self.swap_p][:tick]
                    self.swap_p = self.swap_p + 1
                end

                if sid>pid then
                # do liquidity
                    if _pool[self.pool_p][:block_number]>block_number then
                        self.pool_p = _pool.size
                        next
                    end
                    
                    if _pool[self.pool_p][:liquidity]>0 then
                        # add liquidity
                        x = _pool[self.pool_p][:amount0]
                        y = _pool[self.pool_p][:amount1]
                        l = _pool[self.pool_p][:liquidity]
                        pool_id = _pool[self.pool_p][:pool_id]

                        price_a,price_b = adj_xy2lp(x,y,l,self.cur_price)           

                        find_pool = self.cur_liquidity_pool.map.with_index {|x,i| x[:index]=i;puts x; x}.filter {|x| x[:pool_id]==pool_id }
                        if find_pool.size==1 then                            
                            self.cur_liquidity_pool[find_pool[0][:index]][:l] = self.cur_liquidity_pool[find_pool[0][:index]][:l] + l
                        else
                            self.cur_liquidity_pool.push( {pool_id:pool_id,price_a:price_a,price_b:price_b,l:l}) 
                        end

                        self.pool_p = self.pool_p + 1
                    else
                        # remove liquidity
                        pool_id = _pool[self.pool_p][:pool_id]
                        l = _pool[self.pool_p][:liquidity]


                        find_pool = self.cur_liquidity_pool.map.with_index {|x,i| x[:index]=i; x}.filter {|x| x[:pool_id]==pool_id }
                        if find_pool.size==1 then                            
                            self.cur_liquidity_pool[find_pool[0][:index]][:l] = self.cur_liquidity_pool[find_pool[0][:index]][:l] + l
                            self.cur_liquidity_pool.delete_at(find_pool[0][:index]) if self.cur_liquidity_pool[find_pool[0][:index]][:l]==0
                        else
                            $logger.call _pool[self.pool_p]               
                            raise "the find pool number is wrong"
                        end
                        
                        self.pool_p = self.pool_p + 1
                    end
                end

            end
            self.cur_blocknumber = block_number
            
            return self.cur_liquidity_pool
        end
    end
end


class UniswapV3 < MappingObject

    mapping_accessor :liquidity_pool, :price, :token0, :token1, :token0_decimal, :token1_decimal, :rate
    mapping_accessor :ul_ratio
    
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
        dx = l2x(l,new_price,price_a,price_b) - l2x(l,price,price_a,price_b)
        dy = l2y(l,new_price,price_a,price_b) - l2y(l,price,price_a,price_b)
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
    
    def clean_liquidity(sender=nil)
        self.liquidity_pool = self.liquidity_pool.filter {|x| x[:sender]!=sender }
    end
    
    def clean_fee(sender=nil)
        self.liquidity_pool = self.liquidity_pool.map {|x| x[:token0_fee]=0; x[:token1_fee]=0; x}
    end


    def add_liquidity(x,y,price_a,price_b,sender=nil,run=true)
        if price_a <= price and price <= price_b then
        
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
        return ret_x,ret_y

    end
    
    def remove_liquidity(id,run=true)
        raise NotImplementedError
    end
    
    def slice_liquidity_pool(user="user",user_only=false)

        selectd_liquidity_pool = liquidity_pool
        
        if user_only then
            user_pool = liquidity_pool.filter {|x| x[:sender]==user}
            $logger.call "user_pool len=#{user_pool.length()}"
            if user_pool.size>0 then
                user_upper = user_pool.map {|x| x[:price_b]}.max
                user_lower = user_pool.map {|x| x[:price_a]}.min
                $logger.call "user_upper=#{user_upper} user_lower=#{user_lower} len=#{selectd_liquidity_pool.length()}"
                selectd_liquidity_pool = selectd_liquidity_pool.filter {|x| x[:price_b]>user_lower and x[:price_a]<user_upper }
            else
                selectd_liquidity_pool = []
            end
        end
        $logger.call "selected_liqudity_pool len=#{selectd_liquidity_pool.length()}"

        edge = selectd_liquidity_pool.map {|x| [x[:price_a],x[:price_b]] }.flatten.uniq.sort
        edge = (0..edge.size-2).map.with_index {|x,i|
            lower_price = edge[x]
            upper_price = edge[x+1]
            sub_pool = selectd_liquidity_pool.filter {|pool| pool[:price_a]<= lower_price and upper_price <=pool[:price_b] }
            total_liquidity = sub_pool.map {|x| x[:l]}.sum
            user_liquidity = sub_pool.filter {|pool| pool[:sender]==user }.map {|x| x[:l]}.sum
            {id:i, price_a:lower_price,price_b:upper_price,l:total_liquidity,ul:user_liquidity}
        }
        
        user_pool = -1
        (0..selectd_liquidity_pool.size-1).each do |i|
            if selectd_liquidity_pool[i][:sender]==user then
                user_pool = i
                break
            end
        end
        pool_mapping = edge.map {|x| x[:ul]>0 ? user_pool : -1 }
        
        return edge,pool_mapping
    end
    
    def update_lp_token
        change_price(self.price)
    end
    
    def change_price(new_price,volume0=0,volume1=0,run=false,change_fee=false)
        $logger.call "change price called 2"
        $logger.call "liquidity_pool len= #{liquidity_pool.length()}"
        slice_pool,pool_mapping = self.slice_liquidity_pool("user",true)
        $logger.call "new_price=#{new_price}, volume0=#{volume0}, slice_length=#{slice_pool.length()} slice_pool=#{slice_pool}"
        ul = slice_pool.filter{|x| x[:ul]>0 }.map {|x| x[:ul] }.sum
        l = slice_pool.filter{|x| x[:ul]>0 }.map {|x| x[:l] }.sum
        $logger.call "ul=#{ul}, l=#{l}"
        self.ul_ratio =  (l!=0 ? (ul / l) : 0)

        if run then
            # fee from volume
            pool_index = find_pool(slice_pool,price)
            
            if pool_index then
                pool = slice_pool[pool_index]
                l = pool[:l]
                ul = pool[:ul]
        
                feex = volume0 * self.rate
                feey = volume1 * self.rate
                
                distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
            end    

            # fee from price change
            if change_fee then
                $logger.call "change fee called"
                if new_price > self.price then
                    # direction => higher price
                    loop do
                        # $logger.call "#{pool_index} - #{pool.to_s}"
                        price_a = pool[:price_a]
                        price_b = pool[:price_b]
                        l = pool[:l]
                        ul = pool[:ul]
                        
                        if new_price > price_b then
                            # over the pool
                            next_price = price_b
                            max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
                            feey = max_dy / (1-self.rate) * self.rate
                            feex = 0
                            # $logger.call "[over pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
                            distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                            
                            pool_index = pool_index + 1
                            break if pool_index>=slice_pool.size
                            pool = slice_pool[pool_index]
                        else
                            # within the pool
                            next_price = new_price
                            max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
                            feey = max_dy / (1-self.rate) * self.rate
                            feex = 0
                            # $logger.call "[within pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
                            distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                            
                            break
                        end
                    end
                end
                
                if new_price < self.price then
                    # direction => low price
                    loop do
                        $logger.call "#{pool_index} - #{pool.to_s}"
                        price_a = pool[:price_a]
                        price_b = pool[:price_b]
                        l = pool[:l]
                        ul = pool[:ul]
                        
                        if new_price < price_a then
                            # over the pool
                            next_price = price_a
                            max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
                            feey = 0
                            feex = max_dx / (1-self.rate) * self.rate
                            $logger.call "[over pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
                            distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                            
                            pool_index = pool_index - 1
                            break if pool_index<0
                            pool = slice_pool[pool_index]
                        else
                            # within the pool
                            next_price = new_price
                            max_dx, max_dy = lp2dxdy(l,price,next_price,price_a,price_b)
                            feey = 0
                            feex = max_dx / (1-self.rate) * self.rate
                            $logger.call "[within pool] max_dx=#{max_dx} max_dy=#{max_dy} feex=#{feex} feey=#{feey}"
                            distribute_fee(pool_mapping[pool_index],feex,feey,l,ul)
                            
                            break
                        end
                    end
                end
            end
        end
            
        self.price = new_price

        # change token0 token1 assets
        self.liquidity_pool.map! do |pool|
            if pool[:sender]!=nil then
                price_a = pool[:price_a].to_f
                price_b = pool[:price_b].to_f
                price = self.price.to_f
                
                if price<price_a then
                    price = price_a
                end
                if price>price_b then
                    price = price_b
                end
                vx,vy = self.lp2xy(pool[:l],price,price_a,price_b)
                pool[:token0]=vx.to_f
                pool[:token1]=vy.to_f
            end
            pool
        end
    end
    
    def clean_liquidity_chart
        return @liquidity_chart = nil
    end
    
    def liquidity_chart(add_lower,add_upper,swap_price=nil,swap_l=nil)
        return @liquidity_chart if @liquidity_chart
        if @liquidity_chart==nil then

        pool,pool_maping = slice_liquidity_pool

        data = (-3000..3000).map { |x| 
            lower_price = price*(1.001**x)
            upper_price = price*(1.001**(x+1))
            min_price = (lower_price+upper_price)/2
            # $logger.call lower_price
            # $logger.call upper_price
            # $logger.call pool[0]
            
            if self.token0_decimal!=self.token1_decimal then
                pool = pool.map { |x|
                    x[:price_a] = self.adjp2p(x[:price_a])
                    x[:price_b] = self.adjp2p(x[:price_b])
                    x
                }
            end
            # $logger.call pool.size
            # $logger.call pool[0]
            value = pool.filter {|x| x[:price_a]<=lower_price and upper_price<=x[:price_b]}[0]
            # $logger.call value
            # $logger.call "---------"
            
            {"price":min_price,"value":value[:l],"user_value":value[:ul]} if value             
        }.filter {|x| x!=nil}
        
        
        # $logger.call "swap_price = #{swap_price}  swap_l = #{swap_l}"
        data.push({"price":swap_price, "value":swap_l, "swap":true}) if swap_price!=nil and swap_price>0
        max_l = data.map {|x| x["value"] }.max
        
        @liquidity_chart = spec = 
{
  "title": "Liquidity Pool",
  "width": 500,
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
        "y": {"field": "value", "type": "quantitative", "scale": {"domain": [0, max_l]} },
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
        return @binding_curve = nil
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

def main
    
# init_tick = 0
# user0 mint 10Token 10WETH tick=[-3000, 3000] L=71794946851985505209
# user1 mint 10Token 10WETH tick=[-6000, 6000] L=38584613330867584206
# swap 1.0WETH -> 0.988075240621832TOKEN tick -> 179
# swap 0.988075240621832TOKEN -> 0.9940356946721813WETH tick -> 0
# swap 20.0WETH -> 16.844409861079395TOKEN tick -> 3907
# swap 16.844409861079395TOKEN -> 19.889440908938138WETH tick -> 9
# user0 collect 0.03191360853281438TOKEN 0.03690515405041912WETH
# user1 collect 0.02158384677228931TOKEN 0.026094845949580878WETH    

    uni = UniswapV3.new

    uni.init("TOKEN", "WETH", 18, 18, 1.0001**0, 0.003)

    $logger.call uni.add_liquidity(10,10,1.0001**-3000,1.0001**3000)
    $logger.call uni.add_liquidity(10,10,1.0001**-6000,1.0001**6000,"user")
    
    ret_x,ret_y,price,l = uni.swap(0,1)
    
    $logger.call "ret_x=#{ret_x} ret_y=#{ret_y} price=#{price} l=#{l}"
    $logger.call "sm_price=#{1.0001**179} diff=#{ (price-1.0001**179)/(1.0001**179) }"
    $logger.call "sm_swap_x=#{0.988075240621832} diff=#{ (ret_x-0.988075240621832)/(0.988075240621832) }"
 
    ret_x,ret_y,price,l = uni.swap(0.988075240621832,0)

    $logger.call "ret_x=#{ret_x} ret_y=#{ret_y} price=#{price} l=#{l}"
    $logger.call "sm_price=#{1.0001**0} diff=#{ (price-1.0001**0)/(1.0001**0) }"
    $logger.call "sm_swap_x=#{0.9940356946721813} diff=#{ (ret_y-0.9940356946721813)/(0.9940356946721813) }"


    ret_x,ret_y,price,l = uni.swap(0,20)
    
    $logger.call "ret_x=#{ret_x} ret_y=#{ret_y} price=#{price} l=#{l}"
    $logger.call "sm_price=#{1.0001**3907} diff=#{ (price-1.0001**3907)/(1.0001**3907) }"
    $logger.call "sm_swap_x=#{16.844409861079395} diff=#{ (ret_x-16.844409861079395)/(16.844409861079395) }"
 
    ret_x,ret_y,price,l = uni.swap(16.844409861079395,0)

    $logger.call "ret_x=#{ret_x} ret_y=#{ret_y} price=#{price} l=#{l}"
    $logger.call "sm_price=#{1.0001**9} diff=#{ (price-1.0001**9)/(1.0001**9) }"
    $logger.call "sm_swap_x=#{19.889440908938138} diff=#{ (ret_y-19.889440908938138)/(19.889440908938138) }"
    
    token0_fee = uni.liquidity_pool.filter {|x| x[:sender]=="user" }[0][:token0_fee]
    token1_fee = uni.liquidity_pool.filter {|x| x[:sender]=="user" }[0][:token1_fee]
    $logger.call "fee diff = #{(token0_fee-0.02158384677228931).to_f/0.02158384677228931} / #{(token1_fee-0.026094845949580878).to_f/0.026094845949580878}"


    uni = UniswapV3.new

    uni.init("TOKEN", "WETH", 18, 18, 1.0001**0, 0.003)

    uni.add_liquidity(10,10,1.0001**-3000,1.0001**3000,"user")
    uni.add_liquidity(10,10,1.0001**-6000,1.0001**6000)
    
    ret_x,ret_y,price,l = uni.swap(0,1)
    

    ret_x,ret_y,price,l = uni.swap(0.988075240621832,0)

    ret_x,ret_y,price,l = uni.swap(0,20)

    ret_x,ret_y,price,l = uni.swap(16.844409861079395,0)

    token0_fee = uni.liquidity_pool.filter {|x| x[:sender]=="user" }[0][:token0_fee]
    token1_fee = uni.liquidity_pool.filter {|x| x[:sender]=="user" }[0][:token1_fee]
    $logger.call "fee diff = #{(token0_fee-0.03191360853281438).to_f/0.03191360853281438} / #{(token1_fee-0.03690515405041912).to_f/0.03690515405041912}"

end