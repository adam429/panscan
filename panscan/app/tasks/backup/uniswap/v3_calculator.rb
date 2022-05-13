__TASK_NAME__ = "uniswap/v3_calculator"

# require 'bigdecimal'
# require 'bigdecimal/util'

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))
load(Task.load("uniswap/uniswapv3"))


def main()
    # BigDecimal.limit(100)
    # RenderWrap.before_jsrb("library.bigdecimal","""
    #     require 'bigdecimal'
    #     require 'bigdecimal/util'
    #     BigDecimal.limit(100)
    # """)
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("uniswap/uniswapv3::UniswapV3"))
    
    uni = UniswapV3.new
    uni.init("ETH","USDT",18,12,3000,0.01)
    uni.add_liquidity(5,3000*5,0,9999999999)
    uni.add_liquidity(10,30000,2000,4500)
    uni.add_liquidity(0,30000,1000,2000)
    uni.add_liquidity(10,0,4500,9000)
    uni.add_liquidity(1,3000,2500,3600,"user")

    # $logger.call uni.swap(15,0,false).to_s
    # $logger.call uni.swap(0,3000,false).to_s
    
    # token0,_ = uni.swap(0,38000)
    # _,token1 = uni.swap(token0,0)
    # $logger.call "token1 == #{token1}"


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
      <li>Rate: <%= data[:uni].rate %></li>
      <%= chart binding: :liquidity_pool_chart %>
      <%= chart binding: :binding_curve %><br/>


      
      <h4>Action</h4>
      
      <div id="container">
        <div>
          Add Liquidity</br>
          Lower Price: <%= text binding: :price_a %>
          <%= slider min:10, max:10000, value:10, binding: :price_a %> 
          Upper Price: <%= text binding: :price_b %>
          <%= slider min:0, max:50000, value:50000, binding: :price_b %> 
          [<%= button text:"Price Range to all", action:":price_a=10; :price_b=50000" %>]</br></br>
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
      <h4>Time Machine</h4>
      Change Price: <%= text binding: :sim_price %>
      <%= slider min:1500, max:6000, value:3000, binding: :sim_price %> 
      
      <h4>Liquidity Pool</h4>
      <%= text binding: :liquidity_pool %> 


      <%= calculated_var %( :token0 = $data['uni'].token0 ) %>
      <%= calculated_var %( :token1 = $data['uni'].token1 ) %>
      <%= calculated_var %( :price = $data['uni'].price ) %>
      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :liquidity_pool_chart = $data['uni'].liquidity_chart(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>
      <%= calculated_var %( :binding_curve = $data['uni'].binding_curve(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>
      <%= calculated_var "binding_slider()" %>
      <%= calculated_var "$data['uni'].clean_liquidity_chart; $data['uni'].clean_binding_curve;" %>
    EOS

    RenderWrap.jsrb= <<~EOS
        $logger = ->(x){ puts(x) }
        $logger.call('page ready')

        $saved_swap_token0 = 0
        $saved_swap_token1 = 0
        $saved_add_liquidity_token0 = 0
        $saved_add_liquidity_token1 = 0
        
        def update_swap_calc()
            $saved_swap_token0 = 0
            $saved_swap_token1 = 0
            binding_slider()
        end
        
        def pool_table()
          ret = "<table>"
          ret = ret+"<tr><td>id | </td><td>lower_price | </td><td>upper_price | </td><td>liquidity | </td><td>owner | </td><td>fee0 | </td><td>fee1 | </td><td>token0 | </td><td>token1 | </td></tr>"
          ret = ret+$data['uni'].liquidity_pool.map.with_index {|x,i| "<td>"+i.to_s+"</td>"+x.map{|k,v| "<td>"+v.to_s+"</td>" }.join }.map {|x| "<tr>"+x+"</tr>" }.join
          ret = ret+"</table>"
            # $data['uni'].liquidity_pool.join("<br/>")
        end

        def binding_slider()
          if $saved_sim_price != $vars['sim_price'] then
            #   $logger.call "sim_time change"
              # move world time to new time
              $data["uni"].change_price($vars['sim_price'].to_i)
              $saved_sim_price = $vars['sim_price'] 
              
              calculated_var_update_all()
          end


          if $saved_swap_token0 != $vars['swap_token0'] then
            $saved_swap_token0 = $vars['swap_token0'] 
            cur_price = $data['uni'].price

            _,swap_token0_out,new_price,l = $data['uni'].swap($vars['swap_token0'].to_i,0,false)
            $vars['swap_token0_out'] = swap_token0_out.to_f
            $vars['swap_token_0_price'] = new_price.to_f
            $vars['swap_token_0_slippage'] = ((cur_price.to_f - new_price.to_f)/cur_price.to_f * 100).round(2)
            $vars['swap_price'] = new_price.to_f
            $vars['swap_l'] = l
            calculated_var_update_all()
          end        

          if $saved_swap_token1 != $vars['swap_token1'] then
            $saved_swap_token1 = $vars['swap_token1'] 
            cur_price =  $data['uni'].price

            swap_token1_out,_,new_price,l = $data['uni'].swap(0,$vars['swap_token1'].to_i,false)
            $vars['swap_token1_out'] = swap_token1_out.to_f
            $vars['swap_token_1_price'] = new_price.to_f
            $vars['swap_token_1_slippage'] = ((cur_price.to_f - new_price.to_f)/cur_price.to_f * 100).round(2)
            $vars['swap_price'] = new_price.to_f
            $vars['swap_l'] = l
            calculated_var_update_all()
          end        
        
          if $saved_add_liquidity_token0 != $vars['add_liquidity_token0'] then
              if $vars['price_a'].to_f <= $vars['price'].to_f and $vars['price'].to_f <= $vars['price_b'].to_f then
                  ratio = $data['uni'].calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0'] 
                  $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = ratio[1].to_f/ratio[0].to_f * $vars['add_liquidity_token0'].to_f
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
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = ratio[0].to_f/ratio[1].to_f * $vars['add_liquidity_token1'].to_f
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

