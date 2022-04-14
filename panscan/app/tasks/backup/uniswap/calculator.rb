__TASK_NAME__ = "uniswap/calculator"

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

class UniswapV2 < MappingObject
    def initialize(token0, token1)
        super()
        self.data[:token0] = token0
        self.data[:token1] = token1
        self.data[:liquidity0] = 0
        self.data[:liquidity1] = 0
    end
    
    def l
        return self.data[:liquidity0]*self.data[:liquidity1]
    end
    
    def inspect
        $logger.call "token: #{self.data[:token0]}/#{self.data[:token1]} #{self.data[:liquidity1]/self.data[:liquidity0].to_f} | liquidity: #{self.data[:liquidity0]} / #{data[:liquidity1]} | l: #{self.l}"
    end
    
    def add_liquidity(token0,token1,run=true)
        if self.l==0 then
            $logger.call "add_liquidity in[#{token0} #{token1}] out [0 0]"
            new_liquidity0 = self.data[:liquidity0] + token0
            new_liquidity1 = self.data[:liquidity1] + token1
            self.data[:liquidity0] = new_liquidity0 if run
            self.data[:liquidity1] = new_liquidity1 if run
            return [new_liquidity0,new_liquidity1,0,0]
        else
            delta = [token0 / self.data[:liquidity0], token1 / self.data[:liquidity1]].min
            
            cur_liquidity0 = self.data[:liquidity0]
            cur_liquidity1 = self.data[:liquidity1]
            new_liquidity0 = self.data[:liquidity0] * (1+delta)
            new_liquidity1 = self.data[:liquidity1] * (1+delta)
            
            ret0 = token0-(new_liquidity0-cur_liquidity0)
            ret1 = token1-(new_liquidity1-cur_liquidity1)

            self.data[:liquidity0] = new_liquidity0 if run
            self.data[:liquidity1] = new_liquidity1 if run
            
            $logger.call "add_liquidity in[#{token0} #{token1}] out [#{ret0} #{ret1}}]"
            return [new_liquidity0,new_liquidity1,ret0,ret1]
        end
    end
    
    def binding_curve()
      ret = (self.data[:liquidity0]/5..self.data[:liquidity0]*5).step(1).map.with_index { |x,i| 
          next if x==0
          {"x":x,"y":(self.l/x.to_f).round}
      }
      ret.push({"x"=>self.data[:liquidity0],"y"=>self.data[:liquidity1],"cur"=>true})
    end
    
    def binding_chart(data=[])
    spec = {
      "title": "Binding Curve",
      "width": 200,
      "height": 200,
      "data": {
        "values": self.binding_curve+data
      },
      "layer": [
        {
          "mark": {"type": "line", "interpolate": "monotone"},
          "encoding": {
            "x": {"field": "x", "type": "quantitative"},
            "y": {"field": "y", "type": "quantitative"},
            "tooltip": [{"field": "x"}, {"field": "y"}]
          }
        },
        {
          "transform": [{"filter": "datum.cur == true"}],
          "mark": {"type": "point", "size": 30, "color": "red"},
          "encoding": {
            "x": {"field": "x", "type": "quantitative"},
            "y": {"field": "y", "type": "quantitative"},
            "tooltip": [{"field": "x"}, {"field": "y"}]
          }
        },
        {
          "transform": [{"filter": "datum.swap == true"}],
          "mark": {"type": "point", "size": 30, "color": "green", "shape":"diamond"},
          "encoding": {
            "x": {"field": "x", "type": "quantitative"},
            "y": {"field": "y", "type": "quantitative"},
            "tooltip": [{"field": "x"}, {"field": "y"}]
          }
        },
      ]
 
    }
    end
    
    def remove_liquidity(token0,token1,run=true)
        delta = [token0 / self.data[:liquidity0], token1 / self.data[:liquidity1]].max
        
        cur_liquidity0 = self.data[:liquidity0]
        cur_liquidity1 = self.data[:liquidity1]
        new_liquidity0 = self.data[:liquidity0] * (1-delta)
        new_liquidity1 = self.data[:liquidity1] * (1-delta)
        
        ret0 = token0-(new_liquidity0-cur_liquidity0)
        ret1 = token1-(new_liquidity1-cur_liquidity1)

        self.data[:liquidity0] = new_liquidity0 if run
        self.data[:liquidity1] = new_liquidity1 if run
        
        $logger.call "remove_liquidity in[#{token0} #{token1}] out [#{ret0} #{ret1}}]"
        return [new_liquidity0,new_liquidity1,ret0,ret1]
    end
    
    def swap(token0,token1,run=true)
        cur_liquidity0 = self.data[:liquidity0]
        cur_liquidity1 = self.data[:liquidity1]
        l = self.l
        
        if token0==0 then
            new_liquidity1 = cur_liquidity1 + token1
            new_liquidity0 = self.l / new_liquidity1.to_f
            ret0 = cur_liquidity0 - new_liquidity0
            ret1 = 0
        end
        if token1==0 then
            new_liquidity0 = cur_liquidity0 + token0
            new_liquidity1 = self.l / new_liquidity0.to_f
            ret0 = 0
            ret1 = cur_liquidity1 - new_liquidity1
        end

        self.data[:liquidity0] = new_liquidity0 if run
        self.data[:liquidity1] = new_liquidity1 if run
        
        $logger.call "swap: in[#{token0} #{token1}] - out[#{ret0} #{ret1}]"
        return [new_liquidity0,new_liquidity1,ret0,ret1]
    end
    
end

def main()
    uni = UniswapV2.new("ETH","USDT")
    uni.add_liquidity(10,30000)

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
        </style>

      <h1>Uniswap V2</h1>
      <h4>Stats</h4>
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %></li>
      <li>Liquidity: <%= text binding: :liquidity0 %> * <%= text binding: :liquidity1 %> = <%= text binding: :l %></li>
      <%= chart binding: :binding_chart %> <br/>
      
      <h4>Action</h4>
      
      <div id="container">
        <div>
          Add Liquidity</br>
          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :add_liquidity_token1 %> 
          [<%= button text:"add liquidity", action:"add_liquidity(:add_liquidity_token0, :add_liquidity_token1, true); update_swap_calc()" %>]</br></br>
          [<%= button text:"add ETH:1, USDT: 3000", action:"add_liquidity(1, 3000, true); update_swap_calc()" %>]<br/>
          [<%= button text:"add ETH:10, USDT: 30000", action:"add_liquidity(10, 30000, true); update_swap_calc()" %>]<br/>
          [<%= button text:"add ETH:100, USDT: 300000", action:"add_liquidity(100, 300000, true); update_swap_calc()" %>]<br/>
        </div>
        
        <div>
          Remove Liquidity</br>
          <%= text binding: :token0 %>: <%= text binding: :remove_liquidity_token0 %>
          <%= slider min:0, max:100, value:0, binding: :remove_liquidity_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :remove_liquidity_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :remove_liquidity_token1 %> 
          [<%= button text:"remove liquidity", action:"remove_liquidity(:remove_liquidity_token0, :remove_liquidity_token1,true); update_swap_calc()" %>]</br></br>
          [<%= button text:"remove all", action:"remove_liquidity(:liquidity0, :liquidity1, true); update_swap_calc()" %>]<br/>

        </div>
        
        <div>
          Swap</br>
          <%= text binding: :token0 %>: <%= text binding: :swap_token0 %>
          <%= slider min:0, max:100, value:0, binding: :swap_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :swap_token0_out %><br/>
          Swap Price: <%= text binding: :swap_token_0_price %><br/>
          Slippage Price: <%= text binding: :swap_token_0_slippage %>%<br/><br/>
          [<%= button text: data[:uni][:token0]+"->"+data[:uni][:token1], action:"swap(:swap_token0,0,true); update_swap_calc()" %>]
          <br/><br/>
          --------------------------<br/>
          <%= text binding: :token1 %>: <%= text binding: :swap_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :swap_token1 %> 
          <%= text binding: :token0 %>: <%= text binding: :swap_token1_out %><br/>
          Swap Price: <%= text binding: :swap_token_1_price %><br/>
          Slippage Price: <%= text binding: :swap_token_1_slippage%>%<br/><br/>
          [<%= button text: data[:uni][:token1]+"->"+data[:uni][:token0], action:"swap(0,:swap_token1,true); update_swap_calc()" %>]
        </div>
      </div>
      
      <%= calculated_var "binding_liquidity_token_slider()" %>
      <%= calculated_var "binding_swap_slider()" %>

      <%= calculated_var ":token0 = $data['uni']['token0']" %>
      <%= calculated_var ":token1 = $data['uni']['token1']" %>
      <%= calculated_var ":price = $data['uni']['liquidity1'] / $data['uni']['liquidity0'] " %>
      <%= calculated_var ":liquidity0 = $data['uni']['liquidity0']" %>
      <%= calculated_var ":liquidity1 = $data['uni']['liquidity1']" %>
      <%= calculated_var ":l = $data['uni'].l" %>
      
      <%= calculated_var ":binding_chart = $data['uni'].binding_chart([{'x'=>$vars['swap_liquidity0'],'y'=>$vars['swap_liquidity1'],'swap'=>true}])" %>
      
EOS
    RenderWrap.jsrb= <<~EOS
        $logger = ->(x){ puts(x) }
        
        $logger.call('page ready')
        
        def add_liquidity(token0,token1,run=true)
            $data['uni'].add_liquidity(token0.to_i,token1.to_i,run)
            calculated_var_update_all()
        end


        def remove_liquidity(token0,token1,run=true)
            $data['uni'].remove_liquidity(token0.to_i,token1.to_i,run)
            calculated_var_update_all()
        end

        def swap(token0,token1,run=true)
            $data['uni'].swap(token0.to_i,token1.to_i,run)
            calculated_var_update_all()
        end
        
        def update_swap_calc()
            $saved_swap_token0 = 0
            $saved_swap_token1 = 0
            binding_swap_slider()
        end
            
        $saved_swap_token0 = 0
        $saved_swap_token1 = 0
        
        def binding_swap_slider()
          if $saved_swap_token0 != $vars['swap_token0'] then
            $saved_swap_token0 = $vars['swap_token0'] 
            cur_liquidity0 = $data['uni']['liquidity0']
            cur_liquidity1 = $data['uni']['liquidity1']
            cur_price = cur_liquidity1/cur_liquidity0

            new_liquidity0,new_liquidity1,_,swap_token0_out = $data['uni'].swap($vars['swap_token0'].to_i,0,false)
            $vars['swap_token0_out'] = swap_token0_out
            $vars['swap_token_0_price'] = new_liquidity1/new_liquidity0
            $vars['swap_token_0_slippage'] = ((cur_price - $vars['swap_token_0_price'])/cur_price * 100).round(2)
            $vars['swap_liquidity0'] = new_liquidity0
            $vars['swap_liquidity1'] = new_liquidity1
            calculated_var_update_all()
          end        

          if $saved_swap_token1 != $vars['swap_token1'] then
            $saved_swap_token1 = $vars['swap_token1'] 
            cur_liquidity0 = $data['uni']['liquidity0']
            cur_liquidity1 = $data['uni']['liquidity1']
            cur_price = cur_liquidity1/cur_liquidity0

            new_liquidity0,new_liquidity1,swap_token1_out,_ = $data['uni'].swap(0,$vars['swap_token1'].to_i,false)
            $vars['swap_token1_out'] = swap_token1_out
            $vars['swap_token_1_price'] = new_liquidity1/new_liquidity0
            $vars['swap_token_1_slippage'] = ((cur_price - $vars['swap_token_1_price'])/cur_price * 100).round(2)
            $vars['swap_liquidity0'] = new_liquidity0
            $vars['swap_liquidity1'] = new_liquidity1
            calculated_var_update_all()
          end        
            
            
            

            



        end
        
        $saved_add_liquidity_token0 = 0
        $saved_add_liquidity_token1 = 0
        $saved_remove_liquidity_token0 = 0
        $saved_remove_liquidity_token1 = 0
        
        def binding_liquidity_token_slider()
          return if $data['uni'].l==0
          if $saved_add_liquidity_token0 != $vars['add_liquidity_token0'] then
              $saved_add_liquidity_token0 = $vars['add_liquidity_token0'] 
              $saved_add_liquidity_token1 = $vars['add_liquidity_token1'] = 1_000_000_000 - $data['uni'].add_liquidity($vars['add_liquidity_token0'].to_i,1_000_000_000,false)[3]
              calculated_var_update_all()
          end
          if $saved_add_liquidity_token1 != $vars['add_liquidity_token1'] then
              $saved_add_liquidity_token1 = $vars['add_liquidity_token1'] 
              $saved_add_liquidity_token0 = $vars['add_liquidity_token0'] = 1_000_000_000 - $data['uni'].add_liquidity(1_000_000_000,$vars['add_liquidity_token1'].to_i,false)[2]
              calculated_var_update_all()
          end
          if $saved_remove_liquidity_token0 != $vars['remove_liquidity_token0'] then
              $saved_remove_liquidity_token0 = $vars['remove_liquidity_token0'] 
              $saved_remove_liquidity_token1 = $vars['remove_liquidity_token1'] = $data['uni'].remove_liquidity($vars['remove_liquidity_token0'].to_i,0,false)[3]
              calculated_var_update_all()
          end
          if $saved_remove_liquidity_token1 != $vars['remove_liquidity_token1'] then
              $saved_remove_liquidity_token1 = $vars['remove_liquidity_token1'] 
              $saved_remove_liquidity_token0 = $vars['remove_liquidity_token0'] = $data['uni'].remove_liquidity(0,$vars['remove_liquidity_token1'].to_i,false)[2]
              calculated_var_update_all()
          end

        end
EOS

    RenderWrap[:uni]=uni
    RenderWrap.data
end
