__TASK_NAME__ = "uniswap/simulation_v1"

# require 'bigdecimal'
# require 'bigdecimal/util'
# require 'bigdecimal/math'

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

load(Task.load("uniswap/uniswapv3"))
load(Task.load("uniswap/cex"))
load(Task.load("uniswap/dex"))
load(Task.load("uniswap/graph_query"))

# 数据：价格数据按照小时
# 数据：交易量数据按照天 (24小时平均)
# 假设：CEX忽略资金费率

class Simulation 
    attr_accessor :dex, :cex, :uni, :graph
    
    def initialize(uni,dex,cex,graph)
        @uni = uni
        @dex = dex
        @cex = cex
        @graph = graph
        @time = 99999999
    end
    
    def price
        @uni.price
    end
    
    def time
        @dex.price.reverse[@time][:time]
    end
    
    def time
        @dex.price.reverse[@time][:time]
    end

    def data_import()
        $logger.call "==begin data_import=="
        # read data from graph
        @dex.price = @graph.price
        @dex.volume = @graph.volume

        price_time = @graph.price.map {|x| x[:time] }
        volume_time = @graph.volume.map {|x| x[:time] }

        max_time = [price_time.max,volume_time.max].min
        min_time = [price_time.min,volume_time.min].max

        @dex.price = @dex.price.filter {|x| min_time<=x[:time] and x[:time]<=max_time}
        @dex.volume = @dex.volume.filter {|x| min_time<=x[:time] and x[:time]<=max_time}
        @dex.time_table = @dex.price.reverse.map {|x| {time:x[:time], time_value:x[:time].to_i*1000} }
        
        @uni.price = @graph.cur_price
        @uni.liquidity_pool = @graph.liquidity_pool
        $logger.call "==end data_import=="
    end 
    
    def change_time(new_time)
        return if @time == new_time

        price = @dex.price.reverse[new_time][:close]
        $logger.call "new_time = #{new_time} new_price = #{price}"
        @uni.change_price(price)

        if @time < new_time
            # move to future
        end
        
        if @time > new_time
            # move to past
        end
        @time = new_time
    end
    
end


def main()
    # BigDecimal.limit(32)
    
    # RenderWrap.before_jsrb("library.bigdecimal","require 'bigdecimal'\n require 'bigdecimal/util'\n require 'bigdecimal/math'\n")
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("uniswap/uniswapv3::UniswapV3"))
    RenderWrap.load(Task.load("uniswap/dex::Dex"))
    RenderWrap.load(Task.load("uniswap/cex::Cex"))
    RenderWrap.load(Task.load("uniswap/simulation_v1::Simulation"))

    RenderWrap.load(Task.load("base/widget::pie_chart"))
    RenderWrap.load(Task.load("base/widget::bar_chart"))
    RenderWrap.load(Task.load("base/widget::line_chart"))
    RenderWrap.load(Task.load("base/widget::dist_chart"))
    
    lp_id = "__lp_id__"
    token0 = "__token0__"
    token1 = "__token1__"
    token0_decimal = __token0_decimal__
    token1_decimal = __token1_decimal__
    dex_fee = __dex_fee__
    cex_fee = __cex_fee__
    
    graph = GraphQuery.new(lp_id,token0_decimal,token1_decimal)

    uni = UniswapV3.new
    uni.init(token0,token1,token0_decimal,token1_decimal,nil,dex_fee)
    dex = Dex.new()
    cex = Cex.new(token0,token1,cex_fee)
    
    sim = Simulation.new(uni,dex,cex,graph)
    sim.data_import

    # uni.add_liquidity(100,300000,2800,3300,"user")
    # uni.add_liquidity(0,1000000,2700,2800,"user")
    # uni.add_liquidity(100,0,3100,3200,"user")

    # $logger.call uni.swap(15,0,false).to_s
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
          width: 600px;
        }
        li {
            padding-left: 10px;
        }
        </style>

      <h1>Fee Calculator</h1>
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %> (Rate: <%= data[:uni].rate %>)</li>
    
      <div id="container">
        <div>
          <h4>Liquidity Pool & Price & Volume </h4>
          <%= chart binding: :liquidity_pool_chart %>
          <%= chart binding: :price_chart %><br/>
          <%= chart binding: :volume_chart %><br/>
        </div>
        <div>
          <h4>My Liquidity</h4>
          Lower Price: <%= text binding: :price_a %>
          <%= slider min:(data[:uni].price*0.5).to_i, max:(data[:uni].price*2).to_i, value:(data[:uni].price*0.9).to_i, binding: :price_a %> 
          Upper Price: <%= text binding: :price_b %>
          <%= slider min:(data[:uni].price*0.5).to_i, max:(data[:uni].price*2).to_i, value:(data[:uni].price*1.1).to_i, binding: :price_b %> 
          [<%= button text:"Price Range to 90% - 110%", action:":price_a=(:price.to_f*0.9).to_i; :price_b=(:price.to_f*1.1).to_i " %>]</br></br>
          [<%= button text:"Price Range to last  24 hour price range", action:":price_a, :price_b = $data['dex'].price_range(24) " %>] <%= text binding: :price_in_range_24 %>%</br>
          [<%= button text:"Price Range to last 120 hour price range", action:":price_a, :price_b = $data['dex'].price_range(120) " %>] <%= text binding: :price_in_range_120 %>%</br>
          [<%= button text:"Price Range to last 720 hour price range", action:":price_a, :price_b = $data['dex'].price_range(720) " %>] <%= text binding: :price_in_range_720 %>%</br> </br>

          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <%= slider min:0, max:100000, value:0, binding: :add_liquidity_token1 %> 

          [<%= button text:"add liquidity", action:"$data['uni'].add_liquidity(:add_liquidity_token0.to_f,:add_liquidity_token1.to_f,:price_a.to_f,:price_b.to_f,'user');" %>]</br></br>

          <h4>Liquidity Pool</h4>
          <%= text binding: :liquidity_pool %> 
          
          <h4>Simulation</h4>
          <%= text binding: :sim_time_str %>
          <%= slider min:0, max:data[:dex].count-1, value:data[:dex].count-1, binding: :sim_time %> 
          
          [<%= button text:"move begin", action:"sim_move_begin" %> ]
          [<%= button text:"+1 hour", action:"sim_next_hour" %> ]<br/><br/>
          [<%= button text:"start", action:"play()" %> ] [<%= button text:"stop", action:"stop()" %> ]
        </div>
      </div>
      <div>
      <h4>export data</h4>
      [<%= button text:"generate data", action:"generate_data" %> ] [<a href="#" id="dwn-btn">download</a>] <br/>
      <%= text binding: :export_data %><br/>
      <pre id='text-val' style='display:none' ><%= text binding: :export_data_csv %></pre>
      
      </div>
      <%= calculated_var %( :token0 = $data['uni'].token0 ) %>
      <%= calculated_var %( :token1 = $data['uni'].token1 ) %>
      <%= calculated_var %( :price = $data['uni'].price )  %>
      <%= calculated_var %( :price_in_range_24 = ($data['dex'].price_in_range(:price_a.to_i,:price_b.to_i,24)*100).round(2) ) %>
      <%= calculated_var %( :price_in_range_120 = ($data['dex'].price_in_range(:price_a.to_i,:price_b.to_i,120)*100).round(2) ) %>
      <%= calculated_var %( :price_in_range_720 = ($data['dex'].price_in_range(:price_a.to_i,:price_b.to_i,720)*100).round(2) ) %>
      
      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :liquidity_pool_chart = $data['uni'].liquidity_chart(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>
      <%= calculated_var %( :price_chart = $data['dex'].price_chart(:price_a.to_i, :price_b.to_i, :price.to_i, :sim_time.to_i) ) %>
      <%= calculated_var %( :volume_chart = $data['dex'].volume_chart(:sim_time.to_i) ) %>
      <%= calculated_var %( :sim_time_str = $data['dex'].price.reverse[:sim_time.to_i]["time"][0,16] ) %>
      <%= calculated_var "binding_slider()" %>

    EOS
#      <%= calculated_var %( :binding_curve = $data['uni'].binding_curve(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>

    RenderWrap.jsrb= <<~EOS
  
       
    $data['sim'] = Simulation.new($data['uni'],$data['dex'],$data['cex'],nil)
    
    %x(
function download(filename, text) {
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);

    element.style.display = 'none';
    document.body.appendChild(element);

    element.click();

    document.body.removeChild(element);
}

// Start file download.
document.getElementById("dwn-btn").addEventListener("click", function(){
    // Generate download of hello.txt file with some content
    var text = document.getElementById("text-val").childNodes[1].innerHTML
    var filename = "export.csv";
    
    download(filename, text);
}, false);

    )
    
    def generate_data()
        data = []

        time_end = $data[:dex].count-1
        (0..time_end).each do |time| 
            $logger.call "time - #\{time\}"
            $data["sim"].change_time(time)
            
            lp =  $data["uni"].liquidity_pool.filter{|x| x[:sender]!=nil}

            data.push ( {id:time, 
                         time:$data["sim"].time[0,16], 
                         price:$data["sim"].price, 
                         token0_amt:lp.map {|x| x[:token0]}.sum, 
                         token1_amt:lp.map {|x| x[:token1]}.sum,
                         token0_fee:0, 
                         token1_fee:0} )
        end
        
        $vars['export_data'] = format_table(data, [:id, :time, :price, :token0_amt, :token1_amt])
        $vars['export_data_csv'] = format_csv_table(data, [:id, :time, :price, :token0_amt, :token1_amt])
    end
    
    def stop()
        $play_flag = false
    end
    def play()
        $play_flag = true
        $$[:setTimeout].call(->{ play_callback() },100)
    end
    
    def play_callback()
        if $play_flag then
            sim_next_hour()
            $play_flag = false if $vars[:sim_time].to_i >= $data[:dex].count

            $$[:setTimeout].call(->{ play_callback() },1) 
        end
    end

    def sim_move_begin
        $vars[:sim_time]=0
        $data["sim"].change_time($vars[:sim_time])
        
        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_chart
        $data['dex'].clean_volume_chart
        calculated_var_update_all()
    end

    def sim_next_hour
        $vars[:sim_time]=$vars[:sim_time].to_i+1
        $data["sim"].change_time($vars[:sim_time])

        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_chart
        $data['dex'].clean_volume_chart
        calculated_var_update_all()
    end
    
    def pool_table()
      table = $data['uni'].liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
        x[:id]=i

        x[$data['token0']]=(x[:token0] or 0).round(4)
        x[$data['token1']]=(x[:token1] or 0).round(4)
        x 
      }
      
      format_table(table, [:id, :price_a, :price_b, :l, :fee, $data['token0'], $data['token1']])
    end
    
    def format_table(table, field)
      ret = "<table>"
      ret = ret+"<tr>"
      field.each do |x|
        ret = ret + "<td>| #\{x\}</td>"
      end
      ret = ret+"</tr>"
      table.each do |row|
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td>| #\{row[x].to_s\}</td>"
          end
          ret = ret+"</tr>"
      end
      
      ret = ret+"</table>"
    end
    
    def format_csv_table(table, field)
      ret = ""
      ret = ret + field.map {|x| x.to_s }.join(",")+"\n"
      ret = ret + table.map do |row|
          field.map {|x| row[x].to_s }.join(",")
      end.join("\n")
      ret
    end
        
    
    def binding_slider()
          if $saved_sim_time != $vars['sim_time'] then
              # move world time to new time
              
              new_time = $vars['sim_time'].to_i
              old_time = $saved_sim_time.to_i
              
              $data["sim"].change_time(new_time)
              
              $data['uni'].clean_liquidity_chart
              $data['dex'].clean_price_chart
              $data['dex'].clean_volume_chart
              
              $saved_sim_time = $vars['sim_time'] 
              calculated_var_update_all()
          end
    
          if $saved_price_a != $vars['price_a'] then
              $saved_price_a = $vars['price_a'] 
              $data['uni'].clean_liquidity_chart
              $data['dex'].clean_price_chart
              calculated_var_update_all()
          end

          if $saved_price_b != $vars['price_b'] then
              $saved_price_b = $vars['price_b'] 
              $data['uni'].clean_liquidity_chart
              $data['dex'].clean_price_chart
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
    RenderWrap[:dex]=dex
    RenderWrap[:cex]=cex
    RenderWrap[:token0]=token0
    RenderWrap[:token1]=token1
    RenderWrap.data
end

