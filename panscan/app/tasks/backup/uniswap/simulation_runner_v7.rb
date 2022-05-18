__TASK_NAME__ = "uniswap/simulation_runner_v7"


load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))
load(Task.load("base/data_store"))

load(Task.load("uniswap/uniswapv3_v3"))
load(Task.load("uniswap/cex"))
load(Task.load("uniswap/dex_v3"))
load(Task.load("uniswap/bot_v2"))
load(Task.load("uniswap/simulation_class_v4"))

def simulation_runner(pool_id,sim_data,out_of_service=false)
    $profiler = {}
    
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("uniswap/uniswapv3_v3::(UniswapV3,Pool)"))
    RenderWrap.load(Task.load("uniswap/dex_v3::Dex"))
    RenderWrap.load(Task.load("uniswap/cex::Cex"))
    RenderWrap.load(Task.load("uniswap/bot_v2::Bot"))
    RenderWrap.load(Task.load("uniswap/simulation_class_v4::Simulation"))

    RenderWrap.load(Task.load("base/timeout_each::timeout_each"))
    RenderWrap.load(Task.load("base/widget::dist_chart"))
    $task.name = "uniswap/simulation_runner_v7" if $task.name=="" or $task.name==nil
    
    DataStore.init

    begin
        sim = MappingObject.from_encode_str(sim_data)
        
        sim.user_pool = sim.user_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.pool = sim.pool.pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.swap = sim.pool.swap.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.pool.cur_liquidity_pool = sim.pool.cur_liquidity_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.dex.swap = sim.dex.swap.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.uni.liquidity_pool = sim.uni.liquidity_pool.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }
        sim.bot.config = sim.bot.config.map {|k,v| [k.to_sym,v] }.to_h 
        sim.sim_data = sim.sim_data.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }

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
        $logger.call "sim.bot.config = #{sim.bot.config}"
        
        
        sim.data_size_up()

        if sim.pool.swap.size>0 then
            block_number = sim.pool.swap[sim.sim_time][:block_number]
            sim.user_pool = sim.uni.liquidity_pool.filter {|x| x[:sender]=="user"}
            sim.pool.cur_blocknumber = 9999999999+1
            sim.uni.liquidity_pool = sim.pool.calc_pool(block_number,sim.user_pool)
        end
        
        load_action = sim.load_action =~ /run_simulation_queue/ ? "run_simulation_queue" : ""
        sim.run_load_action
        sim.data_size_down()

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
        $logger.call "sim.bot.config = #{sim.bot.config}"
        $logger.call "bot_stats = #{JSON.dump(sim.bot_stats())}"

    rescue =>e
        $logger.call "== Error on Loading Object =="
        $logger.call e.message
        e.backtrace.each { |line| $logger.call line }
        $logger.call "== Create a new one =="
        sim = Simulation.new
        sim.init(pool_id)
        sim.data_size_down()
    end
    
    all_pools = DataStore.get("all_pools")
    all_pools.sort! {|x,y| "#{x[:token0]}/#{x[:token1]}" <=> "#{y[:token0]}/#{y[:token1]}"}
    pool_option = [""]+ all_pools.map {|p| "#{p[:token0]}/#{p[:token1]} - #{p[:dex_fee]*100}%"}
    pool_option_value = [""]+ all_pools.map {|p| p[:pool]}

    RenderWrap.html= <<~EOS
        <% if data[:out_of_service] %>
            <h1>
              <span style="color:red; font-size: 160px;">Out of Service</span>
            </h1>
            <br/>
            <br/>
            <br/>
            <br/>
            <br/>
        <% end %>

      <%= calculated_var "binding_slider()" %>
      <%= calculated_var %( :simulation_queue = sim_table() ) %>
        
<% if data[:load_action]!="run_simulation_queue" then %>
        <%= select binding: :pool, :option=>data[:pool_option],:option_value=>data[:pool_option_value],:value=>data[:sim].pool_id  %> 
        [<%= button text:"init", action:%( update_task({"update_params"=>{"pool"=> :pool ,"sim_data"=>"-"}}) ) %>]  | 
        [<%= button text:"save", action:%( update_task({"update_params"=>{"sim_data"=>$data['sim'].to_encode_str()}}) ) %>]
        <%= text binding: :status %> | [<%= button text:"update chart", action:"update_chart()" %>] | [ <a href="/task/output/<%= $task.tid %>">status page</a> ]
        <br/><br/>
<% end %>
    
        <style>
        #container {
          display: flex;                  /* establish flex container */
          flex-direction: row;            /* default value; can be omitted */
          flex-wrap: nowrap;              /* default value; can be omitted */
          justify-content: space-between; /* switched from default (flex-start, see below) */
        }
        #container > div {
          width: 1000px;
        }
        li {
            padding-left: 10px;
        }
        </style>

<% if data[:load_action]!="run_simulation_queue" then %>
      <h1>Uniswap V3 Calculator</h1>
<% else %>
      <h1>Simulation Result</h1>
<% end %>
      <li>Token: <%= text binding: :token0 %>/<%= text binding: :token1 %> =  <%= text binding: :price %> (Rate: <%= data[:sim].uni.rate %>)</li>
    
      <div id="container">
        <div>
          <h4>Liquidity Pool & Price & Volume </h4>
          <%= chart binding: :price_volume_chart %><br/>

          <hr/>

<% if data[:load_action]!="run_simulation_queue" then %>
          <h4>Liquidity</h4>
          Lower Price: <%= text binding: :price_a %>
          <br/><%= slider step:0.1, min:-100, max:100, value:-20, binding: :price_a_mul %> <%= input binding: :price_a_mul  %> <br/>
          Upper Price: <%= text binding: :price_b %>
          <br/><%= slider step:0.1, min:-100, max:100, value:20, binding: :price_b_mul %> <%= input binding: :price_b_mul  %> <br/>
          [<%= button text:"Price Range to 90% - 110%", action:":price_a_mul=-10; :price_b_mul=10; update_price(); " %>]</br>
          [<%= button text:"Price Range to 80% - 120%", action:":price_a_mul=-20; :price_b_mul=20; update_price(); " %>]</br>
          [<%= button text:"Price Range to 70% - 130%", action:":price_a_mul=-30; :price_b_mul=30; update_price(); " %>]</br></br>
          Price in Range (<%= text binding: :sim_time_str %> to <%= text binding: :sim_time_end_str %>): <%= text binding: :price_in_range %>% </br></br>

          <%= text binding: :token0 %>: <%= text binding: :add_liquidity_token0 %>
          <br/><%= slider min:0, max:100, value:0, binding: :add_liquidity_token0 %> <%= input binding: :add_liquidity_token0  %> <br/>
          <%= text binding: :token1 %>: <%= text binding: :add_liquidity_token1 %>
          <br/><%= slider min:0, max:100, value:0, binding: :add_liquidity_token1 %> <%= input binding: :add_liquidity_token1  %> <br/>
          <hr/>
          <h4>Bot Configure</h4>
          bot_config: <%= data[:sim].['bot_config'] %>
          <%= load_widgets(data[:sim].bot.config_format, data[:sim].config['bot_config'])  %><br/>
          
<% end %>
  
          <br/><br/>
        </div>
        <div>
<% if data[:load_action]!="run_simulation_queue" then %>
          <h4>Simulation Time</h4>
          Begin Time:<%= text binding: :sim_time_str %>  (<%= text binding: :sim_time %>)
          <br/><%= slider min:0, max:data[:sim].dex.count-1, value:data[:sim].sim_time, binding: :sim_time %>  |
          <%= datetime min:data[:sim].dex.time_str_widget(0), max:data[:sim].dex.time_str_widget(data[:sim].dex.count-1), value:data[:sim].dex.time_str_widget(data[:sim].dex.count-1), binding: :sim_time_datetime %>
          <br/>

          [<%= button text:"move begin", action:"sim_move_begin" %> ]
          [<%= button text:"move end", action:"sim_move_end" %> ]
          <br/><br/>

          End Time:<%= text binding: :sim_time_end_str %>  (<%= text binding: :sim_time_end %>)
          <br/><%= slider min:0, max:data[:sim].dex.count-1, value:data[:sim].sim_time_end, binding: :sim_time_end %> |
          <%= datetime min:data[:sim].dex.time_str_widget(0), max:data[:sim].dex.time_str_widget(data[:sim].dex.count-1), value:data[:sim].dex.time_str_widget(data[:sim].dex.count-1), binding: :sim_time_end_datetime %>
          <br/>
          
          [<%= button text:"move end", action:"sim_end_move_end" %> ]
          <br/>
          
          <hr/>
<% end %>
          
          <h4>Metrics</h4>
          <li>Swap TXs = <%= text binding: :total_swaps %> </li>
          <li>Avg Volume = <%= text binding: ":avg_volume = (:total_volume.to_f / :total_swaps.to_f).round(2)" %> </li>
          <li>Volume = <%= text binding: :total_volume %> </li>
          <li>Hourly TXs Mean = <%= text binding: :hourly_mean %> </li>
          <li>Hourly TXs Deviation = <%= text binding: :hourly_std %> </li>
          <li>Absolute dPrice% Mean = <%= text binding: :adprice_mean %> </li>
          <li>Absolute dPrice% Deviation = <%= text binding: :adprice_std %> </li>
        <%= chart binding: :dist_chart1 %>
        <% calculated_var ':dist_chart1 = dist_chart(:hour_group.map{|x| {"vals"=>x} },"Hourly TXs")' %>
        <%= chart binding: :dist_chart2 %>
        <% calculated_var ':dist_chart2 = dist_chart(:dprice.map{|x| {"vals"=>x} },"Abs dPrice")' %>
        <%= chart binding: :dist_chart3 %>
        <% calculated_var ':dist_chart3 = dist_chart(:dprice.filter {|x| x<=1 }.map{|x| {"vals"=>x} },"Abs dPrice")' %>
          <br/>          

        </div>
      </div>
      <div>


<% if data[:load_action]!="run_simulation_queue" then %>
      <hr/>
      <b> Simulation </b>          
      <%= select binding: :sim_pool, :option=>["==All Pools=="]+data[:pool_option],:option_value=>["==All Pools=="]+data[:pool_option_value],:value=>data[:sim].pool_id  %> 


      [<%= button text:"add to simulation queue", action:"add_to_sim_queue" %> ]
      [<%= button text:"run simulation queue", action:"run_sim_queue" %> ]  <br/></br>

      [<%= button text:"hide input column", action:":column_display = false" %> ]
      [<%= button text:"show input column", action:":column_display = true" %> ] 
      <%= var :column_display, true %>
      <br/>
      
      <%= var :column_sort, :id %>
      <%= var :column_sort_order, :asc %>
      <%= text binding: :simulation_queue %>
      <hr/>
      <span id="dwn-btn"></span><span id="show-btn"></span>

<% else %>
      <h4>Simulation Result</h4>
      
      <b>Config</b><br/>
      <%= text binding: :bot_config %>
      <br/>

      <b>Result</b><br/>
      <%= text binding: :bot_stats %>
      <br/><br/>
      <%= chart binding: :sim_chart %>
      <br/>[<a href="#" id="dwn-btn">download</a>] [<a href="#" id="show-btn">show simulation result</a>]<br/>

      <span id="export_data">
      </span><br/>
      <pre id='text-val' style='display:none' ><span id="export_data_csv">
      </span></pre>
<% end %>


      
      </div>
      <%= calculated_var %( :bot_config = bot_config() ) %>
      <%= calculated_var %( :bot_stats = calc_bot_stats() ) %>
      <%= calculated_var %( :price = $data['sim'].uni.price )  %>
      <%= calculated_var %( :price_in_range = ($data['sim'].dex.price_in_range_from_to(:price_a.to_f,:price_b.to_f,:sim_time.to_i,:sim_time_end.to_i)*100).round(2) ) %>
      <%= calculated_var %( :token0 = $data['sim'].uni.token0 ) %>
      <%= calculated_var %( :token1 = $data['sim'].uni.token1 ) %>
      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :sim_time_str = $data['sim'].dex.time_str(:sim_time.to_i) ) %>
      <%= calculated_var %( :sim_time_end_str = $data['sim'].dex.time_str(:sim_time_end.to_i) ) %>


      <!-- save to ui saver -->
      <%= calculated_var %( $data['sim'].sim_time = (:sim_time.to_i) ) %>
      <%= calculated_var %( $data['sim'].sim_time_end = (:sim_time_end.to_i) ) %>
      <%= calculated_var %( $data['sim'].config['sim_time'] = :sim_time  ) %>
      <%= calculated_var %( $data['sim'].config['sim_time_end'] = :sim_time_end  ) %>
      <%= calculated_var %( $data['sim'].config['price_a_mul'] = :price_a_mul  ) %>
      <%= calculated_var %( $data['sim'].config['price_b_mul'] = :price_b_mul  ) %>
      <%= calculated_var %( $data['sim'].config['add_liquidity_token0'] = :add_liquidity_token0  ) %>
      <%= calculated_var %( $data['sim'].config['add_liquidity_token1'] = :add_liquidity_token1  ) %>
      <%= calculated_var %( $data['sim'].config['bot_config'] = get_widgets_value($data['sim'].bot.config_format)  ) %>

      
    EOS


    RenderWrap.jsrb= <<~EOS
    
    $profiler = {}
    
    def add_one_to_sim_queue(pool_id)
        config = get_widgets_value($data['sim'].bot.config_format)
        config[:sim_time]=$vars['sim_time_str']
        config[:sim_time_end]=$vars['sim_time_end_str']

        config[:pool_id] = pool_id
        config[:pool] = $data['pool_option'][$data['pool_option_value'].index(config[:pool_id])]

        config[:price_a] = $vars[:price_a].to_f
        config[:price_b] = $vars[:price_b].to_f
        config[:price_a_mul] = $vars[:price_a_mul].to_f
        config[:price_b_mul] = $vars[:price_b_mul].to_f
        config[:token0] = $vars[:add_liquidity_token0].to_f
        config[:token1] = $vars[:add_liquidity_token1].to_f
        config[:total_token] = $data['sim'].uni.price * config[:token0] + config[:token1]
        config[:id] = $data['sim'].sim_queue.size
        
        if config[:pool_id]!=$data['sim'].pool_id then
            config[:price_a] = 0
            config[:price_b] = 0
            config[:token0] = 0
            config[:token1] = 0
        end

        $data['sim'].sim_queue.push(config)
    end
    
    def add_to_sim_queue
        if $vars['sim_pool'] == "==All Pools==" then
            $data['pool_option_value'].filter {|x| x.size > 16 }.each do |pool_id|
                add_one_to_sim_queue(pool_id)
            end 
        else
            add_one_to_sim_queue($vars['sim_pool'])
        end
    end
    
    
    def run_sim_queue
        puts "run_sim_queue"
        
        $data['sim'].sim_queue = $data['sim'].sim_queue.map do |x|
            [:task_id,:status_page,:view_page,:total_pnl, :roi_percent, :dex_fee, :cex_fee, :value_diff].each do |y|
                x[y] = nil
            end
            
            x
        end
        
        $data['sim'].change_time($vars[:sim_time].to_i)
        
        timeout_each($data['sim'].sim_queue.filter {|x| x[:pool]!="removed" },0,->(x) {
            $logger.call x 
            cur_bot_config = x

            # load pool data
            $data['sim'].load_action = ["init_pool@#\{x[:pool_id]\}",
                                        "change_time@#\{x[:sim_time]\},#\{x[:sim_time_end]\}",
                                        "add_liqudity@#\{x[:price_a_mul]\},#\{x[:price_b_mul]\},#\{x[:total_token]\}",
                                        "run_simulation_queue"].join("|")

            # load bot config
            $data['sim'].bot.set_config(cur_bot_config)
        
            # load sim_time
            $data['sim'].sim_time = $data['sim'].dex.find_time(x[:sim_time])
            $data['sim'].sim_time_end = $data['sim'].dex.find_time(x[:sim_time_end])
            
            # load liquidity
            $data['sim'].uni.clean_liquidity("user");
            $data['sim'].uni.add_liquidity(x[:token0].to_f,x[:token1].to_f,x[:price_a].to_f,x[:price_b].to_f,"user"); 

            create_task({update_params:{sim_data:$data['sim'].to_encode_str()}}) do |id|
                $data['sim'].sim_queue[x[:id]][:task_id] = id
                check_task_status(x[:id])
            end
        },100,->() { $data['sim'].load_action = "" })

    end
    
    def check_task_status(i)
        x = $data['sim'].sim_queue[i]
        
        return if x[:task_id]==nil
        
        $data['sim'].sim_queue[i][:status_page] = "<a href='/task/output/"+x[:task_id].to_s+"'>unknown</a>"
        $data['sim'].sim_queue[i][:view_page] = "<a href='/task/view/"+x[:task_id].to_s+"'>"+(x[:task_id] or 0).to_s+"</a>"
        calculated_var_update_all()
        
        update_task_status(x[:task_id],->(res) {
            begin
                progress = res["output"].scan(/Simulation Progress \\\\[[ ]*([ 0-9\\\\/]+)[ ]*\\\\]/).last
            rescue
                progress = ["unknown"]
            end
            
            begin
                result = JSON.parse(res["output"].scan(/^bot_stats = (.*)/)[0][0])
            rescue
                result = {}
            end

            $data['sim'].sim_queue[i] = $data['sim'].sim_queue[i].merge(result.map {|k,v| [k.to_sym,v] }.to_h)

            progress = progress[0] if progress!=nil
            progress = progress.to_s
            $data['sim'].sim_queue[i][:status_page] = "<a href='/task/output/"+x[:task_id].to_s+"'>"+res["status"].to_s+"</a> "+progress.to_s
            calculated_var_update_all()
        })
    
    end

    
    def update_task_status(task_id, action)
        HTTP.get "/task/json/#\{task_id\}" do |res|
            $logger.call "network update_task_status #\{task_id\}"
            if res.ok? then
                action.call(res.json)
                
                if res.json["status"]=="run" or res.json["status"]=="open" then
                    $$[:setTimeout].call(->{ update_task_status(task_id,action) },1000)
                end
            else    
                $logger.call "network error, retry in 1s"
                $$[:setTimeout].call(->{ update_task_status(task_id, action) },1000)
            end        
        end
    end
    
    
    def update_widget()
        return
    end
    
    def update_chart()  
        $data['sim'].change_time($vars[:sim_time].to_i)
        calculated_var_update_all()

        $data['sim'].uni.clean_liquidity_chart
        $data['sim'].dex.clean_price_volume_chart
        # $vars[:liquidity_pool_chart] = $data['sim'].uni.liquidity_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:swap_price].to_f, $vars[:swap_l].to_f)
        $vars[:price_volume_chart] = $data['sim'].dex.price_volume_chart($vars[:price_a].to_f, $vars[:price_b].to_f, $vars[:price].to_f, $vars[:sim_time].to_i, $vars[:sim_time_end].to_i)
        $vars[:sim_chart] = $data['sim'].chart($vars[:price_a].to_f, $vars[:price_b].to_f)
        
        calculated_var_update_all({})
    end

    def get_time()
        `new Date().toUTCString()`
    end
    
    def wait_close()
        HTTP.get "/task/json/#{$task.id}" do |res|
            if res.ok? then
                puts "running... status: #\{res.json["status"]\} @ #\{get_time()\}"
                $vars["status"] = "running... status: #\{res.json["status"]\} @ #\{get_time()\}"
                # binding_update_change_all()
                
                if res.json["status"]=="close" then
                    $$.location.reload()
                elsif res.json["status"]=="run" or res.json["status"]=="open" then
                    $$[:setTimeout].call(->{ wait_close() },1000)
                end
            else    
                $logger.call "network error, retry in 1s"
                $$[:setTimeout].call(->{ wait_close() },1000)
            end        
        end
    end
    
    def create_task(params)
        HTTP.post("/task/create/#{$task.id}", payload:params) do |res0|
            if res0.ok? then
                ret = res0.json["id"].to_s
                
                yield(ret)
            else
                $logger.call res0
            end
        end
        return         
    end

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
            else    
                $logger.call "network error, retry in 1s"
                $$[:setTimeout].call(->{ update_task(params) },1000)
            end        
        end
    end


$call_calculated_var_update_all = ->() {
    calculated_var_update_all()
}

gen_table = ->() {
        column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, 
              :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:cex_fee_position, :cex_fee_value,
              :dprice_percent,:value_diff_dex_value_percent,
              :cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, 
              :bot_output,:observation,:trigger,:time_buffer,:volume0,:volume1,:volume,:ul_ratio]
        round = [nil,8,2,2,8,8,8,
                 2,2,2,2,2,8,8,
                 2,2,
                 4,2,2,2,2,
                 nil,nil,nil,nil,2,2,2,4]
        Element['#export_data'].html = format_table($data['sim'].sim_data, column, round)
}

gen_download = ->() {
        column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff, :cex_fee_position, :cex_fee_value, :dprice_percent,:value_diff_dex_value_percent,:cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, :bot_output,:volume0,:volume1,:volume,:ul_ratio]
    Element['#export_data_csv'].html = format_csv_table($data['sim'].sim_data, data_column)
}

  
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
    gen_download()
    
    // Generate download of hello.txt file with some content
    var text = document.getElementById("text-val").childNodes[0].innerHTML
    var filename = "export.csv";
    
    download(filename, text);
}, false);

document.getElementById("show-btn").addEventListener("click", function(){
    gen_table()
}, false);


    )       

    def get_widgets_value(widgets)
       ret = {}
       widgets.map { |x|
           value = { x[:name] => $vars[x[:name]].to_f }
           ret = ret.merge(value)
       }
       return ret
    end
    
    def calc_bot_stats()
        $data['sim'].bot_stats()
    end
    
    def bot_config()
          table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map {|x|
              {"price_a"=>x[:price_a], 
               "price_b"=>x[:price_b], 
               "l"=>x[:l]}
          }
          
          config = $data['sim'].bot.get_config.filter {|x| not ["price_a","price_b","token0","token1", "id","action", "task_id",  "status_page", "view_page", "total_pnl", "roi_percent", "dex_fee", "cex_fee", "value_diff"].include?(x.to_s)}

return """token: #\{$vars[:token0]\} / #\{$vars[:token1]\} = #\{$vars[:price]\} (Rate: #\{ $data[:sim].uni.rate \} ) <br/>
sim_begin_time: #\{$vars[:sim_time_str]\} <br/>
sim_end_time: #\{$vars[:sim_time_end_str]\} <br/>
bot_config #\{config\} <br/>
pool_table: #\{ table \} <br/> """

    end


    def sim_move_begin
        $vars[:sim_time]=0
        calculated_var_update_all()
        
        $$[:setTimeout].call(->{
            $data['sim'].change_time($vars[:sim_time].to_i)
            calculated_var_update_all()
        },10)
    end

    def sim_move_end
        $vars[:sim_time]=$data['sim'].dex.count-1
        calculated_var_update_all()
        $$[:setTimeout].call(->{
            $data['sim'].change_time($vars[:sim_time].to_i)
            calculated_var_update_all()
        },10)
    end
    
    def sim_end_move_end
        $vars[:sim_time_end]=$data['sim'].dex.count-1

        calculated_var_update_all()
    end    
    

    def sim_table()
      table = $data['sim'].sim_queue
      table = table.filter {|x| x[:pool]!="removed"  }
      
      $click_delete_btn = -> (i) {
            puts "click_delete_btn #\{i\}"
            $data['sim'].sim_queue[i.to_i][:pool]='removed'
            calculated_var_update_all()
      }

      table.map {|x,i|
          x[:action] = %( <a href="#/" id="delete_btn_#\{i\}" onclick="Opal.gvars['click_delete_btn'](#\{x[:id]\})">delete</a> )
          x
      }
      

      if table.size > 0 then
        #   $logger.call table[0]
        #   $logger.call table[0][$vars[:column_sort]]
          table = table.sort {|x,y| 
             ($vars[:column_sort_order]=="asc" ? 1 : -1) * (x[ $vars[:column_sort] ].to_f<=>y[ $vars[:column_sort] ].to_f)
          }
      
          if $vars[:column_display] then
              column = [:id,:action,:pool,:amt_hedge,:fee_hedge,:trigger_position,:trigger_price,:trigger_time_buffer,:adj_position_ratio,:sim_time,:sim_time_end,:price_a,:price_b,:price_a_mul,:price_b_mul,:token0,:token1,:total_token,:task_id,:status_page,:view_page,:total_pnl, :roi_percent, :dex_fee, :cex_fee, :value_diff]
              round = [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,8,8,2,2,4,4,4,nil,nil,nil,4, 4, 4, 4, 4]
          else
              column = [:id,:action,:pool,:task_id,:status_page,:view_page,:total_pnl, :roi_percent, :dex_fee, :cex_fee, :value_diff]
              round = [nil,nil,nil,nil,nil,nil,4, 4, 4, 4, 4]
          end
          
          sort =  [column.map {|x| [x, %( <a href='#/' onclick="Opal.gvars.vars.$$smap['column_sort_order']='asc'; Opal.gvars.vars.$$smap['column_sort']='#\{x.to_s}'; Opal.gvars.call_calculated_var_update_all() ">▲</a> <a href='#/' onclick="Opal.gvars.vars.$$smap['column_sort_order']='desc'; Opal.gvars.vars.$$smap['column_sort']='#\{x.to_s}'; Opal.gvars.call_calculated_var_update_all() ">▼</a> ) ]}.to_h]
          return format_table(sort+table, column,round)
      else
          return ""
      end
    end
    
    def pool_table()
      table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
        x[:id]=i

        x[$data['sim'].uni.token0]=(x[:token0] or 0).round(4)
        x[$data['sim'].uni.token1]=(x[:token1] or 0).round(4)
        x[$data['sim'].uni.token0+"_fee"]=$data['sim'].uni.adjd2d((x[:token0_fee] or 0),$data['sim'].uni.token0_decimal).to_f.round(4)
        x[$data['sim'].uni.token1+"_fee"]=$data['sim'].uni.adjd2d((x[:token1_fee] or 0),$data['sim'].uni.token1_decimal).to_f.round(4)
        x 
      }
      format_table(table, [:id, :price_a, :price_b, $data['sim'].uni.token0, $data['sim'].uni.token1, $data['sim'].uni.token0+"_fee", $data['sim'].uni.token1+"_fee"] )
    end
    
def format_table(table, field, round=[], option="")
  ret = "<table style='width: 100%;'>"

  if option!="skip_column" then
      ret = ret+"<tr>"
      field.each do |x|
        ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
      end
      ret = ret+"</tr>"
  end

  table.each_with_index do |row,i|
      ret = ret+"<tr>"
      field.each.with_index do |x,j|

        begin        
            number = round[j]==nil ? (row[x] or 0).to_s : (row[x] or 0).round(round[j]).to_s
        rescue
            number = row[x].to_s
        end
        ret = ret + "<td style='white-space: nowrap;'> | #\{number\}</td>"
      end
      ret = ret+"</tr>"
      
      if (i % 100==99) and option!="skip_column" then
        #   $logger.call "---"
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
          end
          ret = ret+"</tr>"
      end
    
  end
  
  if option!="skip_column" then
  
      ret = ret+"<tr>"
      field.each do |x|
        ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
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
      $vars[:price_a] = $data['sim'].uni.price * (100+$vars[:price_a_mul].to_f)/100 
      $vars[:price_b] = $data['sim'].uni.price * (100+$vars[:price_b_mul].to_f)/100 
      
    #   $data['sim'].uni.clean_liquidity_chart
    #   $data['sim'].dex.clean_price_volume_chart
    end
        
    def update_metric()
        $logger.call "update_metric"
        begin_time = $vars[:sim_time].to_i
        end_time = $vars[:sim_time_end].to_i
        begin_time = $data['sim'].dex.time_table[begin_time]
        end_time = $data['sim'].dex.time_table[end_time]
        
        select_swap =  $data['sim'].dex.swap.filter {|x| begin_time <= x[:time] and x[:time] <= end_time}
        select_swap = select_swap.map {|x| x[:hour] = Time.at(x[:time].to_i).to_s[0,13]; x}.map {|x| 
            # volume0 = $data['sim'].uni.adjd2d(x[:volume0],$data['sim'].uni.token0_decimal).to_f
            # volume1 = $data['sim'].uni.adjd2d(x[:volume1],$data['sim'].uni.token1_decimal).to_f
            # x[:adj_volume] = volume0*x[:price] + volume1
            
            x[:adj_volume] = $data['sim'].uni.adjd2d(x[:volume],$data['sim'].uni.token1_decimal).to_f
            x
        }
        hour_group = select_swap.group_by { |x| x[:hour] }.map {|k,v| v.count}

        $vars[:total_swaps] = select_swap.count
        $vars[:total_volume] = select_swap.map {|x| x[:adj_volume] }.sum.round(2)


        mean = hour_group.sum / hour_group.count.to_f
        std = Math.sqrt(hour_group.map {|x| (x-mean)**2 }.sum/hour_group.count.to_f)
        $vars[:hour_group] = hour_group
        $vars[:hourly_mean] = mean.round(2)
        $vars[:hourly_std] = std.round(2)

        dprice = (0..select_swap.size-2).map {|x| 
            ((select_swap[x+1][:price] / select_swap[x][:price].to_f)-1).abs * 100
        }
        
        mean = dprice.sum / dprice.count.to_f
        std = Math.sqrt(dprice.map {|x| (x-mean)**2 }.sum/dprice.count.to_f)
        $vars[:dprice] = dprice
        $vars[:adprice_mean] = mean.round(4)
        $vars[:adprice_std] = std.round(4)
    end
        
    
    def binding_slider()
#        $logger.call "===binding_slider==="
          if $saved_pool != $vars['pool'] then
              $logger.call "pool change"

              $saved_pool = $vars['pool'] 
              calculated_var_update_all()
          end
        
          if $saved_sim_time != $vars['sim_time'] then
              # move world time to new time
          
              new_time = $vars['sim_time'].to_i
              $saved_sim_time = $vars['sim_time'] 

              $vars[:sim_time_datetime] = $data[:sim].dex.time_str_widget($vars['sim_time'].to_i)
              $saved_sim_time_datetime = $vars[:sim_time_datetime]
              
              
            #   puts "clean timeout "+$sim_time_timeout.to_s
              $$[:clearTimeout].call($sim_time_timeout)

            #   calculated_var_update_all()
              
              $sim_time_timeout = $$[:setTimeout].call(->{
                # puts "timeout"
                $data['sim'].change_time(new_time)
                update_metric                
                calculated_var_update_all()
              },2000)
            #   puts "create timeout "+$sim_time_timeout.to_s

          end

          if $saved_sim_time_end != $vars['sim_time_end'] then
              $saved_sim_time_end = $vars['sim_time_end'] 
              
              $vars[:sim_time_end_datetime] = $data[:sim].dex.time_str_widget($vars['sim_time_end'].to_i)
              $saved_sim_time_end_datetime = $vars[:sim_time_end_datetime]

            #   puts "clean timeout "+$sim_time_end_timeout.to_s
              $$[:clearTimeout].call($sim_time_end_timeout)

            #   calculated_var_update_all()
              $sim_time_end_timeout = $$[:setTimeout].call(->{
                # puts "timeout"
                update_metric                
                calculated_var_update_all()
              },2000)
            #   puts "create timeout "+$sim_time_end_timeout.to_s

          end
          
          if $saved_sim_time_datetime != $vars['sim_time_datetime'] then
            $saved_sim_time_datetime = $vars['sim_time_datetime']
            
            $vars[:sim_time] = $data[:sim].dex.find_time($vars['sim_time_datetime'])
            calculated_var_update_all()
    
          end

          if $saved_sim_time_end_datetime != $vars['sim_time_end_datetime'] then
            $saved_sim_time_end_datetime = $vars['sim_time_end_datetime']
            
            $vars[:sim_time_end] = $data[:sim].dex.find_time($vars['sim_time_end_datetime'])
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
    $vars[:hour_group] = []
    $vars[:dprice] = []

    # init ui config
    $vars[:sim_time] = ($data['sim'].config['sim_time'] or $data['sim'].dex.count-1)
    $vars[:sim_time_end] = ($data['sim'].config['sim_time_end'] or $data['sim'].dex.count-1)
    $vars[:price_a_mul] = ($data['sim'].config['price_a_mul'] or -20)
    $vars[:price_b_mul] = ($data['sim'].config['price_b_mul'] or 20)
    $vars[:add_liquidity_token0] = ($data['sim'].config['add_liquidity_token0'] or 0)
    $vars[:add_liquidity_token1] = ($data['sim'].config['add_liquidity_token1'] or 0)

    $logger.call $data['sim'].bot.config

    
    update_price()
    update_metric()
    update_chart()
    
    Element['#sim_status'].html = ""
    
    $document.body.on (:keydown) do |e|
        $meta_down = true if e.meta?
        $shift_down = true if e.shift?
        if e.key=="Enter" then
            puts "update chart"
            update_metric()
            update_chart()
            e.prevent
        end
    end
    
    $document.body.on (:keyup) do |e|
        $meta_down = false if e.meta?
        $shift_down = false if e.shift?
    end


    $$[:setTimeout].call(->{ $data['sim'].sim_queue.filter{ |x| x[:pool]!='removed' }.each.with_index { |x| check_task_status(x[:id])} },1000)
end


    EOS

    RenderWrap[:load_action]=load_action
    RenderWrap[:sim]=sim
    RenderWrap[:pool_option] = pool_option
    RenderWrap[:pool_option_value] = pool_option_value
    RenderWrap[:out_of_service]=out_of_service
    RenderWrap.data
end


