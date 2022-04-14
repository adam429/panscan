__TASK_NAME__ = "uniswap/v3_calculator"

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

class UniswapV3 < MappingObject
    mapping_accessor :liquidity_pool, :price, :token0, :token1
    
    def initialize(token0, token1, price)
        super()
        
        self.token0 = token0
        self.token1 = token1
        self.liquidity_pool= []
        self.price= price
    end
    
    def inspect
        $logger.call "token: #{self.data[:token0]}/#{self.data[:token1]} #{price}"
    end
    
    def lp2xy(l,price,price_a,price_b)
        x = l * (Math.sqrt(price_b)-Math.sqrt(price))/Math.sqrt(price*price_b)
        y = l * (Math.sqrt(price) - Math.sqrt(price_a))
        return x,y
    end
    
    def lp2dxdy(l,price,new_price,price_a,price_b)
        # dx = l*(1/Math.sqrt(new_price) - 1/Math.sqrt(price))
        # dy = l*(Math.sqrt(new_price) - Math.sqrt(price))
        dx = l2x(l,new_price,price_a,price_b) - l2x(l,price,price_a,price_b)
        dy = l2y(l,new_price,price_a,price_b) - l2y(l,price,price_a,price_b)
        return dx,dy
    end        

    def x2l(x,price,price_a,price_b)
        x * Math.sqrt(price * price_b) / (Math.sqrt(price_b) - Math.sqrt(price))
    end

    def y2l(y,price,price_a,price_b)
        y / (Math.sqrt(price) - Math.sqrt(price_a))
    end
    
    def l2y(l,price,price_a,price_b)
        l * (Math.sqrt(price) - Math.sqrt(price_a))
    end
    
    def l2x(l,price,price_a,price_b)
        l / (Math.sqrt(price * price_b)  / (Math.sqrt(price_b) - Math.sqrt(price)))    
    end
    
    def calc_add_liquidity_ratio(price_a,price_b)
        x = 100
        l = x2l(x,price,price_a,price_b)
        y = l2y(l,price,price_a,price_b)
        $logger.call "[calc_add_liquidity_ratio] (#{price_a},#{price_b})=[#{x},#{y},#{l}}]"
        return [x,y,l]
    end
    
    def add_liquidity(x,y,price_a,price_b,sender=nil,run=true)
        if price_a <= price and price <= price_b then
        
            ex,ey = calc_add_liquidity_ratio(price_a,price_b)
            
            l_x = x2l(x,price,price_a,price_b)
            l_y = y2l(y,price,price_a,price_b)
            l = [l_x,l_y].min
            
            ret_x = x - l2x(l,price,price_a,price_b)
            ret_y = y - l2y(l,price,price_a,price_b)
        end
        
        if price < price_a then
            l = l_x = x2l(x,price,price_a,price_b)
            ret_y = ret_x = 0            
        end

        if price_b < price then
            l = l_y = y2l(y,price,price_a,price_b)
            ret_y = ret_x = 0            
        end

        self.liquidity_pool.push([price_a,price_b,l,sender]) if run and l>0
        $logger.call "[add_liquidity] l = #{l} | ret_x = #{ret_x} | ret_y = #{ret_y}"
        return ret_x,ret_y

    end
    
    def remove_liquidity(id,run=true)
        raise NotImplementedError
    end
    
    def slice_liquidity_pool()
        return liquidity_pool
    end
    
    def swap(x,y,run=true)
        slice_pool = self.slice_liquidity_pool()
        price = self.price
        ret_x = x
        ret_y = y
        
        if ret_x==0 then
            $logger.call "[swap] x=#{x} y=#{y} price=#{price}"
            # direction => right
            
            ## todo here, find pool
            pool_index = 1
            pool = slice_pool[pool_index]
            
            loop do
                if pool[0] <= price and price <= pool[1] then
    
                    $logger.call "[swap slice_pool] #{pool}"
                    price_a = pool[0]
                    price_b = pool[1]
                    l = pool[2]
                    new_price = price_b
                    
                    max_dx, max_dy = lp2dxdy(l,price,new_price,price_a,price_b)
                    $logger.call "[swap slice_pool] new_price=#{new_price} max_dx=#{max_dx} max_dy=#{max_dy}"
                    
                    if max_dy<ret_y then
                        $logger.call "[swap slice_pool] over pool"
                        dy = max_dy
                        dx = max_dx
                        ret_x -= dx
                        ret_y -= dy
                        
                        price = new_price = pool[1]
                        
                        $logger.call "[swap next] dx=#{dx} dy=#{dy} x=#{ret_x} y=#{ret_y} price=#{new_price}"
                        
                        # todo: find next pool
                        pool_index = pool_index + 1
                        pool = slice_pool[pool_index]
                        
                    else
                        $logger.call "[swap slice_pool] within pool"
                        # current pool slice is enough
                        dy = ret_y
                        new_price = (dy/l+Math.sqrt(price))**2
                        dx =  l*(1/Math.sqrt(new_price) - 1/Math.sqrt(price))
                        
                        ret_x -= dx
                        ret_y -= dy
                        
                        $logger.call "[swap return] dx=#{dx} dy=#{dy} x=#{ret_x} y=#{ret_y} price=#{new_price}"
                        price = new_price
    
                        self.price = new_price if run
                        return ret_x, ret_y, new_price
                    end
                    
                end
            
            end


        end
        if y==0 then
        end

        return 0,0,price
    end
    
end

def main()
    uni = UniswapV3.new("ETH","USDT",3000)
    uni.add_liquidity(0,30000,1000,2000)
    uni.add_liquidity(10,30000,2000,4500)
    uni.add_liquidity(10,0,4500,9000)
    uni.swap(0,10000)

    RenderWrap.html= <<~EOS
        <style>
        #container {
          display: flex;                  /* establish flex container */
          flex-direction: row;            /* default value; can be omitted */
          flex-wrap: nowrap;              /* default value; can be omitted */
          justify-content: space-between; /* switched from default (flex-start, see below) */
        }
        #container > div {
          width: 400px;
        }
        li {
            padding-left: 10px;
        }
        </style>

      <h1>Uniswap V3</h1>
      <h4>Stats</h4>
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %></li>
      <li>Liquidity Pool: <%= text binding: :liquidity_pool %> 
        <% chart binding: :liquidity_pool_chart %> <br/>
      </li>
      
      <h4>Action</h4>
      
      <div id="container">
        <div>
          Add Liquidity</br>
          Lower Price: <%= text binding: :price_a %>
          <%= slider min:0, max:9999, value:2000, binding: :price_a %> 
          Upper Price: <%= text binding: :price_b %>
          <%= slider min:0, max:9999, value:4500, binding: :price_b %> 
          [<%= button text:"Price Range to all", action:":price_a=0; :price_b=9999999999" %>]</br></br>
          [<%= button text:"Price Range to 50% - 200%", action:":price_a=:price.to_f*0.5; :price_b=:price.to_f*2 " %>]</br></br>

          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :add_liquidity_token1 %> 

          [<%= button text:"add liquidity", action:"$data['uni'].add_liquidity(:add_liquidity_token0.to_f,:add_liquidity_token1.to_f,:price_a.to_f,:price_b.to_f,'user');" %>]</br></br>
        </div>

        <div>
          Swap</br>
          <%= text binding: :token0 %>: <%= text binding: :swap_token0 %>
          <%= slider min:0, max:100, value:0, binding: :swap_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :swap_token0_out %><br/>
          Swap Price: <%= text binding: :swap_token_0_price %><br/>
          Slippage Price: <%= text binding: :swap_token_0_slippage %>%<br/><br/>
          [<%= button text: data[:uni][:token0]+"->"+data[:uni][:token1], action:"$data['uni'].swap(:swap_token0.to_i,0,true); update_swap_calc()" %>]
          <br/><br/>
          --------------------------<br/>
          <%= text binding: :token1 %>: <%= text binding: :swap_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :swap_token1 %> 
          <%= text binding: :token0 %>: <%= text binding: :swap_token1_out %><br/>
          Swap Price: <%= text binding: :swap_token_1_price %><br/>
          Slippage Price: <%= text binding: :swap_token_1_slippage%>%<br/><br/>
          [<%= button text: data[:uni][:token1]+"->"+data[:uni][:token0], action:"$data['uni'].swap(0,:swap_token1.to_i,true); update_swap_calc()" %>]
        </div>

      </div>

      <%= calculated_var %( :token0 = $data['uni'].token0 ) %>
      <%= calculated_var %( :token1 = $data['uni'].token1 ) %>
      <%= calculated_var %( :price = $data['uni'].price ) %>
      <%= calculated_var %( :liquidity_pool = $data['uni'].liquidity_pool.map.with_index {|x,i| "<li>"+i.to_s+"|"+x.join("|")+"</li>"  }.join() ) %>

      <%= calculated_var "binding_slider()" %>

    EOS

    RenderWrap.jsrb= <<~EOS
        $logger = ->(x){ puts(x) }
        $logger.call('page ready')

        $saved_swap_token0 = 0
        $saved_swap_token1 = 0
        $saved_add_liquidity_token0 = 0
        $saved_add_liquidity_token1 = 0
        
        def update_swap_calc()
            puts "update_swap_calc"
        end
        

        def binding_slider()
          if $saved_swap_token0 != $vars['swap_token0'] then
            $saved_swap_token0 = $vars['swap_token0'] 
            cur_price = $data['uni'].price

            _,swap_token0_out,new_price = $data['uni'].swap($vars['swap_token0'].to_i,0,false)
            $vars['swap_token0_out'] = swap_token0_out
            $vars['swap_token_0_price'] = new_price
            $vars['swap_token_0_slippage'] = ((cur_price - new_price)/cur_price * 100).round(2)
            calculated_var_update_all()
          end        

          if $saved_swap_token1 != $vars['swap_token1'] then
            $saved_swap_token1 = $vars['swap_token1'] 
            cur_price =  $data['uni'].price

            swap_token1_out,_,new_price = $data['uni'].swap(0,$vars['swap_token1'].to_i,false)
            $vars['swap_token1_out'] = swap_token1_out
            $vars['swap_token_1_price'] = new_price
            $vars['swap_token_1_slippage'] = ((cur_price - new_price)/cur_price * 100).round(2)
            calculated_var_update_all()
          end        
        
          if $saved_add_liquidity_token0 != $vars['add_liquidity_token0'] then
              if $vars['price_a'].to_f <= $vars['price'].to_f and $vars['price'].to_f <= $vars['price_b'].to_f then
                  ratio = $data['uni'].calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0'] 
                  $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = ratio[1]/ratio[0] * $vars['add_liquidity_token0'].to_f
                  calculated_var_update_all()
              end
              if $vars['price'].to_f<$vars['price_a'].to_f then
                 $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = 0
              end
              if $vars['price_b'].to_f<$vars['price'].to_f then
                 $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = 0
                 calculated_var_update_all()
              end
          end
          
          if $saved_add_liquidity_token1 != $vars['add_liquidity_token1'] then
              if $vars['price_a'].to_f <= $vars['price'].to_f and $vars['price'].to_f <= $vars['price_b'].to_f then
                  ratio = $data['uni'].calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
                  $saved_add_liquidity_token1 = $vars['add_liquidity_token1'] 
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = ratio[0]/ratio[1] * $vars['add_liquidity_token1'].to_f
                  calculated_var_update_all()
              end
              if $vars['price'].to_f<$vars['price_a'].to_f then
                 $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = 0
                 calculated_var_update_all()
              end
              if $vars['price_b'].to_f<$vars['price'].to_f then
                 $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = 0
              end
          end
        end
        
    EOS

    RenderWrap[:uni]=uni
    RenderWrap.data
end

