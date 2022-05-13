__TASK_NAME__ = "uniswap/simulation_v8_adam4"

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
load(Task.load("uniswap/simulation_v2"))

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
    RenderWrap.load(Task.load("uniswap/simulation_v2::Simulation"))

    DataStore.init

    pool_id = "__pool__"
    
    pool_config = DataStore.get("uniswap.#{pool_id}")

    token0 = pool_config[:token0]
    token1 = pool_config[:token1]
    token0_decimal = pool_config[:token0_decimal]
    token1_decimal = pool_config[:token1_decimal]
    dex_fee = pool_config[:dex_fee]
    cex_fee = pool_config[:cex_fee]
    sim_data = "__sim_data__"

    begin
        sim = MappingObject.from_encode_str(sim_data)
        
        sim.user_pool = sim.user_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.pool = sim.pool.pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.swap = sim.pool.swap.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.cur_liquidity_pool = sim.pool.cur_liquidity_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.dex.swap = sim.dex.swap.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.uni.liquidity_pool = sim.uni.liquidity_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }

        $logger.call "sim.pool_id = #{sim.pool_id}"
        $logger.call "sim.sim_time = #{sim.sim_time}"
        $logger.call "sim.sim_time_end = #{sim.sim_time_end}"
        $logger.call "sim.load_action = #{sim.load_action}"
        $logger.call "sim.sim_data = #{sim.sim_data.first}"
        $logger.call "sim.user_pool = #{sim.user_pool}"
        $logger.call "sim.pool.cur_liquidity_pool = #{sim.pool.cur_liquidity_pool}"
        $logger.call "sim.pool.init_tick = #{sim.pool.init_tick}"
        $logger.call "sim.pool.pool = #{sim.pool.pool.first}"
        $logger.call "sim.pool.swap = #{sim.pool.swap.first}"
        $logger.call "sim.uni.liquidity_pool = #{sim.uni.liquidity_pool.first}"
        $logger.call "sim.uni.price = #{sim.uni.price}"
        $logger.call "sim.uni.token0 = #{sim.uni.token0}"
        $logger.call "sim.uni.token1 = #{sim.uni.token1}"
        $logger.call "sim.uni.token0_decimal = #{sim.uni.token0_decimal}"
        $logger.call "sim.uni.token1_decimal = #{sim.uni.token1_decimal}"
        $logger.call "sim.uni.rate = #{sim.uni.rate}"
        $logger.call "sim.uni.ul_ratio = #{sim.uni.ul_ratio}"
        $logger.call "sim.dex.swap = #{sim.dex.swap.first}"
        $logger.call "sim.dex.time_table = #{sim.dex.time_table.first}"
        
        sim.run_load_action

    rescue =>e
        $logger.call "== Error on Loading Object. Create a new one =="
        $logger.call e.message
        e.backtrace.each { |line| $logger.call line }

        uni = UniswapV3.new
        uni.init(token0,token1,token0_decimal,token1_decimal,nil,dex_fee)
        dex = Dex.new()
        cex = Cex.new()
        cex.init(token0,token1,cex_fee)
        bot = Bot.new
        pool = Pool.new
        pool.init()
        sim = Simulation.new
        sim.init(uni,dex,cex,pool,bot)
        sim.data_import(pool_id)
        sim.run_load_action
    end
    
    all_pools = DataStore.get("all_pools")
    all_pools.sort! {|x,y| "#{x[:token0]}/#{x[:token1]}" <=> "#{y[:token0]}/#{y[:token1]}"}
    pool_option = [""]+ all_pools.map {|p| "#{p[:token0]}/#{p[:token1]} - #{p[:dex_fee]*100}% pool"}
    pool_option_value = [""]+ all_pools.map {|p| p[:pool]}


    # uni.add_liquidity(100,300000,2800,3300,"user")
    # uni.add_liquidity(0,1000000,2700,2800,"user")
    # uni.add_liquidity(100,0,3100,3200,"user")

    # $logger.call uni.swap(15,0,false).to_s
    # token0,_ = uni.swap(0,38000)
    # _,token1 = uni.swap(token0,0)
    # $logger.call "token1 == #{token1}"
        # <h1>
        #   <span style="color:red; font-size: 160px;">Out of Service</span>
        # </h1>
        # <br/>
        # <br/>
        # <br/>
        # <br/>
        # <br/>
        
    

    RenderWrap.html= <<~EOS
          <%= calculated_var %( $data['sim'].sim_time = (:sim_time.to_i) ) %>
          <%= calculated_var %( $data['sim'].sim_time_end = (:sim_time_end.to_i) ) %>
          
        <%= select binding: :pool, :option=>data[:pool_option],:option_value=>data[:pool_option_value],:value=>data[:sim].pool_id  %> 
        [<%= button text:"init", action:%( update_task({"update_params"=>{"pool"=> :pool ,"sim_data"=>"-"}}) ) %>]  | 
        [<%= button text:"save", action:%( update_task({"update_params"=>{"sim_data"=>$data["sim"].to_encode_str()}}) ) %>]
        <%= text binding: :status %> | [<%= button text:"update chart", action:"update_chart()" %>] | [ <a href="/task/output/<%= $task.tid %>">status page</a> ]
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
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %> (Rate: <%= data[:sim].uni.rate %>)</li>
    
      <div id="container">
        <div>
          <h4>Liquidity Pool & Price & Volume </h4>
          <%= chart binding: :liquidity_pool_chart %>
          <%= chart binding: :price_volume_chart %><br/>
        </div>
        <div>
          <h4>Time Machine</h4>
          Current Time:<%= text binding: :sim_time_str %>
          <br/><%= slider min:0, max:data[:sim].dex.count-1, value:data[:sim].sim_time, binding: :sim_time %> <br/>
          
          [<%= button text:"move begin", action:"sim_move_begin" %> ]
          [<%= button text:"+1 swap", action:"sim_next_hour" %> ]
          [<%= button text:"move end", action:"sim_move_end" %> ]
          <br/><br/>
          [<%= button text:"start", action:"play()" %> ] [<%= button text:"stop", action:"stop()" %> ]
          <br/><br/>

          End Time:<%= text binding: :sim_time_end_str %>
          <br/><%= slider min:0, max:data[:sim].dex.count-1, value:data[:sim].sim_time_end, binding: :sim_time_end %> <br/>
          
          [<%= button text:"move end", action:"sim_end_move_end" %> ]
          <br/><br/>
          
          

          <h4>Liquidity</h4>
          Lower Price: <%= text binding: :price_a %>
          <br/><%= slider min:-100, max:100, value:-20, binding: :price_a_mul %> <%= input binding: :price_a_mul  %> <br/>
          Upper Price: <%= text binding: :price_b %>
          <br/><%= slider min:-100, max:100, value:20, binding: :price_b_mul %> <%= input binding: :price_b_mul  %> <br/>
          [<%= button text:"Price Range to 90% - 110%", action:":price_a_mul=-10; :price_b_mul=10; update_price(); " %>]</br>
          [<%= button text:"Price Range to 80% - 120%", action:":price_a_mul=-20; :price_b_mul=20; update_price(); " %>]</br>
          [<%= button text:"Price Range to 70% - 130%", action:":price_a_mul=-30; :price_b_mul=30; update_price(); " %>]</br></br>
          Price in Range (<%= text binding: :sim_time_str %> to <%= text binding: :sim_time_end_str %>): <%= text binding: :price_in_range %>% </br></br>

          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <br/><%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> <%= input binding: :add_liquidity_token0  %> <br/>
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <br/><%= slider min:0, max:100, value:0, binding: :add_liquidity_token1 %> <%= input binding: :add_liquidity_token1  %> <br/>

          [<%= button text:"add liquidity", action:"add_liquidity()" %>]</br></br>

          <h4>Liquidity Pool</h4>
          User Liquidity Rate: <%= text binding: ":ul_ratio = $data['sim'].uni.ul_ratio" %>
          <br/>[<%= button text:"clean liquidity", action:"clean_liquidity()" %>]</br></br>
          <%= text binding: :liquidity_pool %> 
        </div>
      </div>
      <div>
      <h4>Simulation</h4>
      Bot Config: <%= data[:sim].bot.bot_config %><br><br>
      [<%= button text:"start simulation frontend", action:"generate_data" %> ] [<%= button text:"start simulation backend", action:"generate_data_backend" %> ] [<a href="#" id="dwn-btn">download</a>] <br/>
      <%= text binding: :sim_status %><span id='sim_status'></span><br/><br/>

      <%= chart binding: :sim_chart %>


      <%= text binding: :export_data %><br/>
      <pre id='text-val' style='display:none' ><%= text binding: :export_data_csv %></pre>
      
      </div>
      
      
      <%= calculated_var %( :token0 = $data['sim'].uni.token0 ) %>
      <%= calculated_var %( :token1 = $data['sim'].uni.token1 ) %>
      <%= calculated_var %( :price = $data['sim'].uni.price )  %>
      <%= calculated_var %( :price_in_range = ($data['sim'].dex.price_in_range_from_to(:price_a.to_f,:price_b.to_f,:sim_time.to_i,:sim_time_end.to_i)*100).round(2) ) %>

      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :sim_time_str = $data['sim'].dex.time_str(:sim_time.to_i) ) %>
      <%= calculated_var %( :sim_time_end_str = $data['sim'].dex.time_str(:sim_time_end.to_i) ) %>
      <%= calculated_var "binding_slider()" %>

    EOS
    #   <%= calculated_var %( :liquidity_pool_chart = $data['uni'].liquidity_chart(:price_a.to_f, :price_b.to_f, :swap_price.to_f, :swap_l.to_f) ) %>
    #   <%= calculated_var %( :price_volume_chart = $data['dex'].price_volume_chart(:price_a.to_f, :price_b.to_f, :price.to_f, :sim_time.to_i) ) %>
    #   <%= calculated_var %( :sim_chart = $data['sim'].chart() ) %>

#      <%= calculated_var %( :binding_curve = $data['uni'].binding_curve(:price_a.to_i, :price_b.to_i, :swap_price.to_f, :swap_l.to_f) ) %>
    #   sim.pool = <%= text binding: ":fooa = $data['sim'].pool.cur_liquidity_pool.filter {|x| x['sender']=='user' }" %> <br/>
    #   sim.uni = <%= text binding: ":foob = $data['sim'].uni.liquidity_pool.filter {|x| x['sender']=='user' }" %><br/>
    #   sim.user_pool = <%= text binding: ":fooc = $data['sim'].user_pool.filter {|x| x['sender']=='user' }" %><br/>

    #   sim.pool = <%= text binding: ":food = $data['sim'].pool.cur_liquidity_pool.size" %> <br/>
    #   sim.uni = <%= text binding: ":fooe = $data['sim'].uni.liquidity_pool.size" %><br/>
    #   sim.user_pool = <%= text binding: ":foof = $data['sim'].user_pool.size" %><br/>


    RenderWrap.jsrb= <<~EOS
    
    def update_chart()  
        puts "update_chart"
    
        $data["sim"].change_time($vars[:sim_time].to_i)
        calculated_var_update_all()

        $data['sim'].uni.clean_liquidity_chart
        $data['sim'].dex.clean_price_volume_chart
    
        $vars[:liquidity_pool_chart] = $data['sim'].uni.liquidity_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:swap_price].to_f, $vars[:swap_l].to_f)
        $vars[:price_volume_chart] = $data['sim'].dex.price_volume_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:price].to_f, $vars[:sim_time].to_i)
        $vars[:sim_chart] = $data['sim'].chart()
        
        calculated_var_update_all()
        binding_update_change_chart_all()
    end

    def get_time()
        `new Date().toUTCString()`
    end
    
    def wait_close()
        HTTP.get "/task/json/#{$task.id}" do |res|
            if res.ok? then
                puts "running... status: #\{res.json["status"]\} @ #\{get_time()\}"
                $vars["status"] = "running... status: #\{res.json["status"]\} @ #\{get_time()\}"
                binding_update_change_all()
                
                if res.json["status"]=="close" then
                    $$.location.reload()
                elsif res.json["status"]=="run" or res.json["status"]=="open" then
                    $$[:setTimeout].call(->{ wait_close() },1000)
                end
            end        
        end
    end

    # def reload(params)
    #     puts "reload"
        
    #     $vars["status"] = "running..."
    #     binding_update_change_all()
    #     HTTP.get("/task/status/#{$task.id}/open") do |res|
    #       if res.ok? then
    #         $$[:setTimeout].call(->{ wait_close() },1000)
    #       end        
    #     end
    # end

    def update_task(params)
        # puts "update_task"
        
        $vars["status"] = "running..."
        binding_update_change_all()
        
        HTTP.post("/task/params/#{$task.id}", payload:params) do |res0|
            if res0.ok? then
                HTTP.get("/task/status/#{$task.id}/open") do |res1|
                  if res1.ok? then
                    $$[:setTimeout].call(->{ wait_close() },1000)
                  end        
                end
            end
        end
    end

  
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

    def clean_liquidity()
        $data['sim'].clean_liquidity()
        $data['sim'].uni.update_lp_token; 
        $data["sim"].change_time($vars[:sim_time].to_i)
        calculated_var_update_all()
   end


    def add_liquidity()
        $data['sim'].uni.add_liquidity($vars[:add_liquidity_token0].to_f,$vars[:add_liquidity_token1].to_f,$vars[:price_a].to_f,$vars[:price_b].to_f,'user'); 
        $data['sim'].uni.update_lp_token; 
        $data["sim"].change_time($vars[:sim_time].to_i)
        calculated_var_update_all()
   end
    
    def generate_data()
        $data['sim'].simulate($vars[:sim_time].to_i,$vars[:sim_time_end].to_i, ->(data){
            data_column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:dprice,:value_diff_dex_value,:cex_fee,:total_pnl,:roi,:unhedged_pnl,:unhedged_roi, :bot_output,:volume0,:volume1,:volume,:ul_ratio]
            $vars['export_data'] = format_table(data, data_column)
            $vars['export_data_csv'] = format_csv_table(data, data_column)
            update_chart()
        })
    end

    def generate_data_backend()
          table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
            x[:id]=i
    
            x[$data['token0']]=(x[:token0] or 0).round(4)
            x[$data['token1']]=(x[:token1] or 0).round(4)
            x[$data['token0']+"_fee"]=(x[:token0_fee] or 0).round(4)
            x[$data['token1']+"_fee"]=(x[:token1_fee] or 0).round(4)
            x 
          }.join("\n")

        user_confirm = confirm("""===Start Backend Simulation===
Token: #\{$vars[:token0]\} / #\{$vars[:token1]\} = #\{$vars[:price]\} (Rate: #\{ $data[:sim].uni.rate \} )
sim_begin_time: #\{$vars[:sim_time_str]\}
sim_end_time: #\{$vars[:sim_time_end_str]\}
pool_table:
#\{ table \}""")
        if user_confirm then
            $data["sim"].change_time($vars[:sim_time].to_i)
            $data["sim"].load_action = "run_simulation"
            update_task({update_params:{sim_data:$data["sim"].to_encode_str()}})
        end
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
            $play_flag = false if $vars[:sim_time].to_i >= $data[:sim].dex.count

            $$[:setTimeout].call(->{ play_callback() },1) 
        end
    end

    def sim_move_begin
        $vars[:sim_time]=0
        $data["sim"].change_time($vars[:sim_time].to_i)
        
        calculated_var_update_all()
    end

    def sim_next_hour
        $vars[:sim_time]=$vars[:sim_time].to_i+1
        $data["sim"].change_time($vars[:sim_time].to_i)

        calculated_var_update_all()
    end

    def sim_move_end
        $vars[:sim_time]=$data['sim'].dex.count-1
        $data["sim"].change_time($vars[:sim_time].to_i)

        calculated_var_update_all()
    end
    
    def sim_end_move_end
        $vars[:sim_time_end]=$data['sim'].dex.count-1

        calculated_var_update_all()
    end    
    
    def pool_table()
      table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
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
      table.each_with_index do |row,i|
      
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td style='white-space: nowrap;'> | #\{row[x].to_s\}</td>"
          end
          ret = ret+"</tr>"
          
        #   $logger.call i
          if (i % 100==99) then
            #   $logger.call "---"
              ret = ret+"<tr>"
              field.each do |x|
                ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
              end
              ret = ret+"</tr>"
          end
          
      end
      ret = ret+"<tr>"
      field.each do |x|
        ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
      end
      ret = ret+"</tr>"
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
      $vars[:price_a] = $data['sim'].uni.price * (100+$vars[:price_a_mul].to_f)/100 
      $vars[:price_b] = $data['sim'].uni.price * (100+$vars[:price_b_mul].to_f)/100 
      
      $data['sim'].uni.clean_liquidity_chart
      $data['sim'].dex.clean_price_volume_chart
      
    end
        
    
    def binding_slider()
          if $saved_pool != $vars['pool'] then
              $logger.call "pool change"

              $saved_pool = $vars['pool'] 
              calculated_var_update_all()
          end
        
          if $saved_sim_time != $vars['sim_time'] then
            #   $logger.call "sim_time change"
              # move world time to new time
              
              new_time = $vars['sim_time'].to_i
              old_time = $saved_sim_time.to_i
              
              $data["sim"].change_time(new_time)
              
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
                  ratio = $data['sim'].uni.calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
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
                  ratio = $data['sim'].uni.calc_add_liquidity_ratio($vars['price_a'].to_f,$vars['price_b'].to_f)
        
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
    $logger.call RUBY_ENGINE
    
    if $data["sim"].sim_data!=nil and  $data["sim"].sim_data[0]!=nil then
        data_column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:dprice,:value_diff_dex_value,:cex_fee,:total_pnl,:roi,:unhedged_pnl,:unhedged_roi, :bot_output,:volume0,:volume1,:volume,:ul_ratio]
        $vars['export_data'] = format_table($data["sim"].sim_data, data_column)
        $vars['export_data_csv'] = format_csv_table($data["sim"].sim_data, data_column)
    end
    update_chart()
    
    Element['#sim_status'].html = ""
    
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

    RenderWrap[:sim]=sim
    RenderWrap[:token0]=token0
    RenderWrap[:token1]=token1
    RenderWrap[:pool_option] = pool_option
    RenderWrap[:pool_option_value] = pool_option_value
    RenderWrap.data
end

