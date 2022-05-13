__TASK_NAME__ = "uniswap/simulation_v5"

# require 'bigdecimal'
# require 'bigdecimal/util'
# require 'bigdecimal/math'

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))
load(Task.load("base/data_store"))

load(Task.load("uniswap/uniswapv3_v2"))
load(Task.load("uniswap/cex"))
load(Task.load("uniswap/dex_v2"))
load(Task.load("uniswap/bot"))
load(Task.load("uniswap/simulation"))

# 数据：价格数据按照小时
# 数据：交易量数据按照天 (24小时平均)
# 假设：CEX忽略资金费率






def main()
    # BigDecimal.limit(32)
    
    # RenderWrap.before_jsrb("library.bigdecimal","require 'bigdecimal'\n require 'bigdecimal/util'\n require 'bigdecimal/math'\n")
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("uniswap/uniswapv3_v2::(UniswapV3,Pool)"))
    RenderWrap.load(Task.load("uniswap/dex_v2::Dex"))
    RenderWrap.load(Task.load("uniswap/cex::Cex"))
    RenderWrap.load(Task.load("uniswap/bot::Bot"))
    RenderWrap.load(Task.load("uniswap/simulation::Simulation"))

    DataStore.init


    token0 = "__token0__"
    token1 = "__token1__"
    token0_decimal = __token0_decimal__
    token1_decimal = __token1_decimal__
    dex_fee = __dex_fee__
    cex_fee = __cex_fee__
    

    uni = UniswapV3.new
    uni.init(token0,token1,token0_decimal,token1_decimal,nil,dex_fee)
    
    dex = Dex.new()
    cex = Cex.new(token0,token1,cex_fee)
    
    bot = Bot.new
    pool = Pool.new

    sim = Simulation.new(uni,dex,cex,pool,bot)
    sim.data_import
    

    # uni.add_liquidity(100,300000,2800,3300,"user")
    # uni.add_liquidity(0,1000000,2700,2800,"user")
    # uni.add_liquidity(100,0,3100,3200,"user")

    # $logger.call uni.swap(15,0,false).to_s
    # token0,_ = uni.swap(0,38000)
    # _,token1 = uni.swap(token0,0)
    # $logger.call "token1 == #{token1}"


        #   Lower Price: <%= text binding: :price_a %>
        #   <%= slider min:(data[:uni].price*0.5).to_i, max:(data[:uni].price*2).to_i, value:(data[:uni].price*0.9).to_i, binding: :price_a %> 
        #   Upper Price: <%= text binding: :price_b %>
        #   <%= slider min:(data[:uni].price*0.5).to_i, max:(data[:uni].price*2).to_i, value:(data[:uni].price*1.1).to_i, binding: :price_b %> 
        #   [<%= button text:"Price Range to last  24 hour price range", action:":price_a, :price_b = $data['dex'].price_range(24) " %>] <%= text binding: :price_in_range_24 %>%</br>
        #   [<%= button text:"Price Range to last 120 hour price range", action:":price_a, :price_b = $data['dex'].price_range(120) " %>] <%= text binding: :price_in_range_120 %>%</br>
        #   [<%= button text:"Price Range to last 720 hour price range", action:":price_a, :price_b = $data['dex'].price_range(720) " %>] <%= text binding: :price_in_range_720 %>%</br> </br>
    #   <%= calculated_var %( :price_in_range_24 = ($data['dex'].price_in_range(:price_a,:price_b,24)*100).round(2) ) %>
    #   <%= calculated_var %( :price_in_range_120 = ($data['dex'].price_in_range(:price_a,:price_b,120)*100).round(2) ) %>
    #   <%= calculated_var %( :price_in_range_720 = ($data['dex'].price_in_range(:price_a,:price_b,720)*100).round(2) ) %>


        # <h1>
        #   <span style="color:red; font-size: 160px;">Out of Service</span>
        # </h1>
        # <br/>
        # <br/>
        # <br/>
        # <br/>
        # <br/>
   
    RenderWrap.html= <<~EOS
        [<%= button text:"reload", action:"reload()" %>]
        <%= text binding: :status %>
        <br/><br/>

        [<%= button text:"update chart", action:"update_chart()" %>]
        <br/><br/>
    
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

      <h1>Uniswap V3 Calculator</h1>
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %> (Rate: <%= data[:uni].rate %>)</li>
    
      <div id="container">
        <div>
          <h4>Liquidity Pool & Price & Volume </h4>
          <%= chart binding: :liquidity_pool_chart %>
          <%= chart binding: :price_volume_chart %><br/>
        </div>
        <div>
          <h4>Time Machine</h4>
          <%= text binding: :sim_time_str %>
          <%= slider min:0, max:data[:dex].count-1, value:data[:dex].count-1, binding: :sim_time %> 
          
          [<%= button text:"move begin", action:"sim_move_begin" %> ]
          [<%= button text:"+1 swap", action:"sim_next_hour" %> ]
          [<%= button text:"move end", action:"sim_move_end" %> ]
          <br/><br/>
          
          [<%= button text:"start", action:"play()" %> ] [<%= button text:"stop", action:"stop()" %> ]

          <h4>Liquidity</h4>
          Lower Price: <%= text binding: :price_a %>
          <%= slider min:-100, max:100, value:-20, binding: :price_a_mul %> 
          Upper Price: <%= text binding: :price_b %>
          <%= slider min:-100, max:100, value:20, binding: :price_b_mul %> 
          [<%= button text:"Price Range to 90% - 110%", action:":price_a_mul=-10; :price_b_mul=10; update_price(); " %>]</br>
          [<%= button text:"Price Range to 80% - 120%", action:":price_a_mul=-20; :price_b_mul=20; update_price(); " %>]</br>
          [<%= button text:"Price Range to 70% - 130%", action:":price_a_mul=-30; :price_b_mul=30; update_price(); " %>]</br></br>
          Price in Range (<%= text binding: :sim_time_str %> to now): <%= text binding: :price_in_range %>% </br></br>

          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> 
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <%= slider min:0, max:100, value:0, binding: :add_liquidity_token1 %> 

          [<%= button text:"add liquidity", action:"$data['uni'].add_liquidity(:add_liquidity_token0.to_f,:add_liquidity_token1.to_f,:price_a.to_f,:price_b.to_f,'user'); $data['uni'].update_lp_token;" %>]</br></br>

          <h4>Liquidity Pool</h4>
          <%= text binding: :liquidity_pool %> 
        </div>
      </div>
      <div>
      <h4>Simulation</h4>
      Bot Config: <%= Bot::Config.to_s %><br><br>
      [<%= button text:"start simulation", action:"generate_data" %> ] [<a href="#" id="dwn-btn">download</a>] <br/>
      <%= text binding: :sim_status %><br/>

      <%= chart binding: :sim_chart %>


      <%= text binding: :export_data %><br/>
      <pre id='text-val' style='display:none' ><%= text binding: :export_data_csv %></pre>
      
      </div>
      <%= calculated_var %( :token0 = $data['uni'].token0 ) %>
      <%= calculated_var %( :token1 = $data['uni'].token1 ) %>
      <%= calculated_var %( :price = $data['uni'].price )  %>
      <%= calculated_var %( :price_in_range = ($data['dex'].price_in_range_from(:price_a.to_f,:price_b.to_f,:sim_time.to_i)*100).round(2) ) %>

      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :sim_time_str = $data['dex'].time_str(:sim_time.to_i) ) %>
      <%= calculated_var "binding_slider()" %>

    EOS
    #   <%= calculated_var %( :liquidity_pool_chart = $data['uni'].liquidity_chart(:price_a.to_f, :price_b.to_f, :swap_price.to_f, :swap_l.to_f) ) %>
    #   <%= calculated_var %( :price_volume_chart = $data['dex'].price_volume_chart(:price_a.to_f, :price_b.to_f, :price.to_f, :sim_time.to_i) ) %>
    #   <%= calculated_var %( :sim_chart = $data['sim'].chart() ) %>

#      <%= calculated_var %( :binding_curve = $data['uni'].binding_curve(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>


    RenderWrap.jsrb= <<~EOS
    
    def update_chart()  
        puts "update_chart"
    
        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_volume_chart
    
        $vars[:liquidity_pool_chart] = $data['uni'].liquidity_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:swap_price].to_f, $vars[:swap_l].to_f)
        $vars[:price_volume_chart] = $data['dex'].price_volume_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:price].to_f, $vars[:sim_time].to_i)
        $vars[:sim_chart] = $data['sim'].chart()
        
        calculated_var_update_all()
        binding_update_change_chart_all()
    end

    
    def wait_close()
        HTTP.get "/task/json/#{$task.id}" do |res|
            if res.ok? then
                puts res.json["status"]
                if res.json["status"]=="close" then
                    $$.location.reload()
                elsif res.json["status"]=="run" or res.json["status"]=="open" then
                    $vars["status"] = "running... status: #\{res.json["status"]\}"
                    binding_update_change_all()
                    $$[:setTimeout].call(->{ wait_close() },1000)
                end
            end        
        end
    end

    def reload()
        puts "reload"
        
        $vars["status"] = "running..."
        binding_update_change_all()
        HTTP.get("/task/status/#{$task.id}/open") do |res|
          if res.ok? then
            $$[:setTimeout].call(->{ wait_close() },1000)
          end        
        end
    end

  
    $data['bot'] = Bot.new
    $data['sim'] = Simulation.new($data['uni'],$data['dex'],$data['cex'],$data['pool'],$data['bot'])

    # update_chart()
    
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
        data = $data['sim'].simulate($vars[:sim_time].to_i,$data[:dex].count-1)
        data_column = data[0].map {|k,v| k}
        $vars['export_data'] = format_table(data, data_column)
        $vars['export_data_csv'] = format_csv_table(data, data_column)
        update_chart()
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
        $data["sim"].change_time($vars[:sim_time].to_i)
        
        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_volume_chart
        calculated_var_update_all()
    end

    def sim_next_hour
        $vars[:sim_time]=$vars[:sim_time].to_i+1
        $data["sim"].change_time($vars[:sim_time].to_i)

        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_volume_chart
        calculated_var_update_all()
    end

    def sim_move_end
        $vars[:sim_time]=$data['dex'].count-1
        $data["sim"].change_time($vars[:sim_time].to_i)
        
        $data['uni'].clean_liquidity_chart
        $data['dex'].clean_price_volume_chart
        calculated_var_update_all()
    end
    
    def pool_table()
      table = $data['uni'].liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
        x[:id]=i

        x[$data['token0']]=(x[:token0] or 0).round(4)
        x[$data['token1']]=(x[:token1] or 0).round(4)
        x[$data['token0']+"_fee"]=(x[:token0_fee] or 0).round(4)
        x[$data['token1']+"_fee"]=(x[:token1_fee] or 0).round(4)
        x 
      }
      format_table(table, [:id, :price_a, :price_b, $data['token0'], $data['token1'], $data['token0']+"_fee", $data['token1']+"_fee"] )
    end
    
    def format_table(table, field)
      ret = "<table style='width: 100%;'>"
      ret = ret+"<tr>"
      field.each do |x|
        ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
      end
      ret = ret+"</tr>"
      table.each do |row|
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td style='white-space: nowrap;'> | #\{row[x].to_s\}</td>"
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
    
    def update_price()
      $vars[:price_a] = $data['uni'].price * (100+$vars[:price_a_mul].to_f)/100 
      $vars[:price_b] = $data['uni'].price * (100+$vars[:price_b_mul].to_f)/100 
      
      $data['uni'].clean_liquidity_chart
      $data['dex'].clean_price_volume_chart
      
    end
        
    
    def binding_slider()
          if $saved_sim_time != $vars['sim_time'] then
            #   $logger.call "sim_time change"
              # move world time to new time
              
              new_time = $vars['sim_time'].to_i
              old_time = $saved_sim_time.to_i
              
              $data["sim"].change_time(new_time)
              
              $data['uni'].clean_liquidity_chart
              $data['dex'].clean_price_volume_chart
              
              $saved_sim_time = $vars['sim_time'] 
              calculated_var_update_all()
          end
    
          if $saved_price_a != $vars['price_a_mul'] then
            #   $logger.call "price_a_mul change"
              $saved_price_a = $vars['price_a_mul'] 
              update_price()
              
              calculated_var_update_all()
          end

          if $saved_price_b != $vars['price_b_mul'] then
            #   $logger.call "price_b_mul change"
              $saved_price_b = $vars['price_b_mul'] 
              update_price()
              
              calculated_var_update_all()
          end
        
        #   $logger.call " #\{$saved_add_liquidity_token0\} #\{$vars['add_liquidity_token0'] \}  #\{$saved_add_liquidity_token1\} #\{$vars['add_liquidity_token1'] \}"
    
          if $saved_add_liquidity_token0 != $vars['add_liquidity_token0'] then
                $saved_add_liquidity_token0 = $vars['add_liquidity_token0']           
                # $logger.call "add liquidity token0 change #\{$saved_add_liquidity_token0\} #\{$vars['add_liquidity_token0'] \}"
                
              if $vars['price_a'].to_f <= $vars['price'].to_f and $vars['price'].to_f <= $vars['price_b'].to_f then
                  ratio = $data['uni'].calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0'] 
                  $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = (ratio[1]/ratio[0]).to_f * ($vars['add_liquidity_token0']).to_f
                #   update_price()

                  calculated_var_update_all()
              end
              if $vars['price'].to_f<$vars['price_a'].to_f then
                 $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = 0
              end
              if $vars['price_b'].to_f<$vars['price'].to_f then
                 $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = 0
                #  update_price()
               
                 calculated_var_update_all()
              end

          end
          
          if $saved_add_liquidity_token1 != $vars['add_liquidity_token1'] then
                $saved_add_liquidity_token1 = $vars['add_liquidity_token1']           
                # $logger.call "add liquidity token1 change #\{$saved_add_liquidity_token1\} #\{$vars['add_liquidity_token1'] \}"
              if $vars['price_a'].to_f <= $vars['price'].to_f and $vars['price'].to_f <= $vars['price_b'].to_f then
                  ratio = $data['uni'].calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
                  $saved_add_liquidity_token1 = $vars['add_liquidity_token1'] 
                  $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = (ratio[0]/ratio[1]).to_f * ($vars['add_liquidity_token1']).to_f
                #   update_price()

                  calculated_var_update_all()
              end
              if $vars['price'].to_f<$vars['price_a'].to_f then
                 $saved_add_liquidity_token1 = $vars['add_liquidity_token1']  = 0
                #  update_price()

                 calculated_var_update_all()
              end
              if $vars['price_b'].to_f<$vars['price'].to_f then
                 $saved_add_liquidity_token0 = $vars['add_liquidity_token0']  = 0
              end
          end
        end

$document.ready do    
    update_chart()
    
    $document.body.on (:keydown) do |e|
        $meta_down = true if e.meta?
        $shift_down = true if e.shift?
        if e.key=="Enter" then
            puts "update chart"
            update_chart()
            e.prevent
        end
    end
    $document.body.on (:keyup) do |e|
        $meta_down = false if e.meta?
        $shift_down = false if e.shift?
    end

end


    EOS

    RenderWrap[:uni]=uni
    RenderWrap[:dex]=dex
    RenderWrap[:cex]=cex
    RenderWrap[:bot]=bot
    RenderWrap[:pool]=pool
    RenderWrap[:token0]=token0
    RenderWrap[:token1]=token1
    RenderWrap.data
end

