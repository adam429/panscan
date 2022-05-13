__TASK_NAME__ = "uniswap/simulation_runner_v6"


load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))
load(Task.load("base/data_store"))

load(Task.load("uniswap/uniswapv3_v3"))
load(Task.load("uniswap/cex"))
load(Task.load("uniswap/dex_v3"))
load(Task.load("uniswap/bot_v2"))
load(Task.load("uniswap/simulation_class_v3"))



# 数据：价格数据按照小时
# 数据：交易量数据按照天 (24小时平均)
# 假设：CEX忽略资金费率

def format_table(table, field, round)
  ret = "<table style='width: 100%;'>"
  ret = ret+"<tr>"
  field.each do |x|
    ret = ret + "<td style='white-space: nowrap;'> | #{x}</td>"
  end
  ret = ret+"</tr>"
  table.each_with_index do |row,i|
      ret = ret+"<tr>"
    #   $logger.call row
      field.each.with_index do |x,j|
    #   $logger.call x
    #   $logger.call round[j]
    #   $logger.call row[x.to_s]
          
        ret = ret + "<td style='white-space: nowrap;'> | #{ 
            round[j]==nil ? (row[x] or 0).to_s : (row[x] or 0).round(round[j]).to_s
        }</td>"
      end
      ret = ret+"</tr>"
      
    #   $logger.call i
      if (i % 100==99) then
        #   $logger.call "---"
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td style='white-space: nowrap;'> | #{x}</td>"
          end
          ret = ret+"</tr>"
      end
      
  end
  ret = ret+"<tr>"
  field.each do |x|
    ret = ret + "<td style='white-space: nowrap;'> | #{x}</td>"
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


def simulation_runner(pool_id,sim_data,out_of_service=false)
    RenderWrap.load(Task.load("base/widget::dist_chart"))
    
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
        # sim.bot.config_format = sim.bot.config_format.map {|x| x.map {|k,v| [k.to_sym,v] }.to_h }

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
        
        $task.name = "uniswap/simulation_runner_v6" if $task.name=="" or $task.name==nil
        
        sim.data_size_up()
        

        if sim.pool.swap.size>0 then
            block_number = sim.pool.swap[sim.sim_time][:block_number]
            sim.user_pool = sim.uni.liquidity_pool.filter {|x| x[:sender]=="user"}
            sim.pool.cur_blocknumber = 9999999999+1
            sim.uni.liquidity_pool = sim.pool.calc_pool(block_number,sim.user_pool)
        end
        

#hack
# sim.sim_time_end = sim.sim_time + 10
#hack


        saved_sim_load_action = sim.load_action
        sim.run_load_action
        sim.data_size_down()

    rescue =>e
        $logger.call "== Error on Loading Object. Create a new one =="
        $logger.call e.message
        e.backtrace.each { |line| $logger.call line }

        pool_config = DataStore.get("uniswap.#{pool_id}")
        pool_config = Simulation.reverse_pool(pool_config)
        
        token0 = pool_config[:token0]
        token1 = pool_config[:token1]
        token0_decimal = pool_config[:token0_decimal]
        token1_decimal = pool_config[:token1_decimal]
        dex_fee = pool_config[:dex_fee]
        cex_fee = pool_config[:cex_fee]

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
        sim.data_size_down()

        # sim.change_time(sim.sim_time)
        # raise "here"
    end
    
    all_pools = DataStore.get("all_pools")
    all_pools.sort! {|x,y| "#{x[:token0]}/#{x[:token1]}" <=> "#{y[:token0]}/#{y[:token1]}"}
    pool_option = [""]+ all_pools.map {|p| "#{p[:token0]}/#{p[:token1]} - #{p[:dex_fee]*100}% pool"}
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
        
<% if data[:load_action]!="run_simulation_queue" then %>
        
      <%= calculated_var "binding_slider()" %>
      <%= calculated_var %( :simulation_queue = sim_table() ) %>

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
          width: 1000px;
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
          <%= chart binding: :price_volume_chart %><br/>
          <h4>Bot Configure</h4>
          Bot initial config: <%= data[:sim].bot.get_config %><br><br>

          <%= load_widgets(data[:sim].bot.config_format)  %><br/>
          
          <b> Single Simulation </b>          
          [<%= button text:"start simulation", action:"generate_data_backend" %> ]  <br/>
          <%= text binding: :sim_status %><span id='sim_status'></span><br/><br/>
          
          <b> Multiple Simulation </b>          
          [<%= button text:"add to simulation queue", action:"add_to_sim_queue" %> ]
          [<%= button text:"run simulation queue", action:"run_sim_queue" %> ]  <br/></br>
          
          <%= text binding: :simulation_queue %>
      
          <br/><br/>
        </div>
        <div>
          <h4>Simulation</h4>
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

          [<%= button text:"add liquidity", action:"add_liquidity()" %>]</br></br>

          <h4>Liquidity Pool</h4>
          <br/>[<%= button text:"clean liquidity", action:"clean_liquidity()" %>]</br></br>
          <%= text binding: :liquidity_pool %> 
        </div>
      </div>
      <div>
<% end %>        

      <%= calculated_var %( :bot_config = bot_config() ) %>
      <%= calculated_var %( :bot_stats = bot_stats() ) %>
      <%= calculated_var %( :price = $data['sim'].uni.price )  %>
      <%= calculated_var %( :price_in_range = ($data['sim'].dex.price_in_range_from_to(:price_a.to_f,:price_b.to_f,:sim_time.to_i,:sim_time_end.to_i)*100).round(2) ) %>
      <%= calculated_var %( $data['sim'].sim_time = (:sim_time.to_i) ) %>
      <%= calculated_var %( $data['sim'].sim_time_end = (:sim_time_end.to_i) ) %>
      <%= calculated_var %( :token0 = $data['sim'].uni.token0 ) %>
      <%= calculated_var %( :token1 = $data['sim'].uni.token1 ) %>
      <%= calculated_var %( :liquidity_pool = pool_table() ) %>
      <%= calculated_var %( :sim_time_str = $data['sim'].dex.time_str(:sim_time.to_i) ) %>
      <%= calculated_var %( :sim_time_end_str = $data['sim'].dex.time_str(:sim_time_end.to_i) ) %>



      <h4>Simulation Result</h4>
      <b>Config</b><br/>
      <%= text binding: :bot_config %>
      <br/>

      <b>Result</b><br/>
      <%= text binding: :bot_stats %>
      <br/><br/>
      <%= chart binding: :sim_chart %>

      
      <br/>[<a href="#" id="dwn-btn">download</a>]<br/>

      <span id="export_data">
        <%= 
            column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, 
                      :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:dprice_percent,:value_diff_dex_value_percent,
                      :cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, 
                      :bot_output,:observation,:trigger,:time_buffer,:volume0,:volume1,:volume,:ul_ratio]
            round = [nil,8,2,2,8,8,8,
                     2,2,2,2,2,2,2,
                     4,2,2,2,2,
                     nil,nil,nil,nil,2,2,2,4]
            format_table(data[:sim].sim_data, column, round) 
        %>
      </span><br/>
      <pre id='text-val' style='display:none' ><span id="export_data_csv">
      </span></pre>

      
      </div>
      
      
    EOS

# $bindings = <%= OpalBinding.instance.bindings.map{|x| x.to_s}.join("<br/>") %>
# <br/>
# $vars = <%= OpalBinding.instance.vars.merge(OpalBinding.instance.define_vars) %>)
# <br/>
    #   <%= text binding: :export_data %><br/>
    #   <pre id='text-val' style='display:none' ><%= text binding: :export_data_csv %></pre>

    RenderWrap.jsrb= <<~EOS
    
    def add_to_sim_queue
        $data['sim'].sim_queue.push(get_widgets_value($data['sim'].bot.config_format))
    end
    
    def run_sim_queue
        puts "run_sim_queue"
        
        $data["sim"].change_time($vars[:sim_time].to_i)
        $data["sim"].load_action = "run_simulation_queue"

        $data['sim'].sim_queue.map.with_index do |x,i|
            $data['sim'].bot.set_config(x)
            create_task({update_params:{sim_data:$data["sim"].to_encode_str()}}) do |id|
                $data['sim'].sim_queue[i][:task_id] = id
                $data['sim'].sim_queue[i][:status_page] = "<a href='/task/output/"+x[:task_id]+"'>"+x[:task_id]+"</a>"
                $data['sim'].sim_queue[i][:view_page] = "<a href='/task/view/"+x[:task_id]+"'>"+x[:task_id]+"</a>"
                calculated_var_update_all()
                
                update_task_status(id,->(res) {
                    progress = res["output"].scan(/Simulation Progress \\\\[[ ]*([ 0-9\\\\/]+)[ ]*\\\\]/).last
                    progress = progress[0] if progress!=nil
                    progress = progress.to_s
                    $data['sim'].sim_queue[i][:status_page] = "<a href='/task/output/"+x[:task_id]+"'>"+res["status"]+"</a> "+progress
                    calculated_var_update_all()
                })
                
            end
        end 
    end
    
    def update_task_status(task_id, action)
        HTTP.get "/task/json/#\{task_id\}" do |res|
            if res.ok? then
                action.call(res.json)
                
                if res.json["status"]=="run" or res.json["status"]=="open" then
                    $$[:setTimeout].call(->{ update_task_status(task_id,action) },1000)
                end
            end        
        end
    end
    
    
    def update_widget()
        return
    end
    
    def update_chart()  
        $data["sim"].change_time($vars[:sim_time].to_i)
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
            end        
        end
    end
    
    def create_task(params)
        HTTP.post("/task/create/#{$task.id}", payload:params) do |res0|
            puts res0.json
            if res0.ok? then
                ret = res0.json["id"].to_s
                
                yield(ret)
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
            end
        end
    end

gen_download = ->() {
    data_column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:dprice_percent,:value_diff_dex_value_percent,:cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, :bot_output,:observation,:trigger,:time_buffer,:volume0,:volume1,:volume,:ul_ratio]
    Element['#export_data_csv'].html = format_csv_table($data["sim"].sim_data, data_column)
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
    
    def get_widgets_value(widgets)
       ret = {}
       widgets.map { |x|
           value = { x[:name] => $vars[x[:name]].to_f }
           ret = ret.merge(value)
       }
       return ret
    end
    
    def bot_stats()
        if $data['sim'].sim_data!=nil and $data['sim'].sim_data!=[] then
            return {
                total_pnl:$data['sim'].sim_data[-1][:total_pnl],
                unhedged_pnl:$data['sim'].sim_data[-1][:unhedged_pnl],

                dex_fee:$data['sim'].sim_data[-1][:total_fee],
                cex_fee:$data['sim'].sim_data[-1][:cex_fee],
                value_diff:$data['sim'].sim_data[-1][:value_diff],
            }
        end
    end
    
    def bot_config()
          table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map {|x|
              {"price_a"=>x[:price_a], 
               "price_b"=>x[:price_b], 
               "l"=>x[:l]}
          }

return """token: #\{$vars[:token0]\} / #\{$vars[:token1]\} = #\{$vars[:price]\} (Rate: #\{ $data[:sim].uni.rate \} ) <br/>
sim_begin_time: #\{$vars[:sim_time_str]\} <br/>
sim_end_time: #\{$vars[:sim_time_end_str]\} <br/>
bot_config #\{$data['sim'].bot.get_config\} <br/>
pool_table: #\{ table \} <br/> """

    end

    def generate_data_backend()
          table = $data['sim'].uni.liquidity_pool.filter{|x| x[:sender]!=nil }.map.with_index {|x,i|
            x[:id]=i
    
            x[$data['sim'].uni.token0]=(x[:token0] or 0).round(4)
            x[$data['sim'].uni.token1]=(x[:token1] or 0).round(4)
            x[$data['sim'].uni.token0+"_fee"]=$data['sim'].uni.adjd2d((x[:token0_fee] or 0),$data['sim'].uni.token0_decimal).to_f.round(4)
            x[$data['sim'].uni.token1+"_fee"]=$data['sim'].uni.adjd2d((x[:token1_fee] or 0),$data['sim'].uni.token1_decimal).to_f.round(4)
            x 
          }.join("\n")

          
        $data['sim'].bot.set_config(get_widgets_value($data['sim'].bot.config_format))

        user_confirm = confirm("""===Start Backend Simulation===
Token: #\{$vars[:token0]\} / #\{$vars[:token1]\} = #\{$vars[:price]\} (Rate: #\{ $data[:sim].uni.rate \} )
sim_begin_time: #\{$vars[:sim_time_str]\}
sim_end_time: #\{$vars[:sim_time_end_str]\}
bot_config #\{$data['sim'].bot.get_config\}
pool_table:
#\{ table \}""")
        if user_confirm then
            $data["sim"].change_time($vars[:sim_time].to_i)
            $data["sim"].load_action = "run_simulation"
            encode_str = $data["sim"].to_encode_str()
            update_task({update_params:{sim_data:encode_str}})
        end
    end

    def sim_move_begin
        $vars[:sim_time]=0
        calculated_var_update_all()
        
        $$[:setTimeout].call(->{
            $data["sim"].change_time($vars[:sim_time].to_i)
            calculated_var_update_all()
        },10)
    end

    def sim_move_end
        $vars[:sim_time]=$data['sim'].dex.count-1
        calculated_var_update_all()
        $$[:setTimeout].call(->{
            $data["sim"].change_time($vars[:sim_time].to_i)
            calculated_var_update_all()
        },10)
    end
    
    def sim_end_move_end
        $vars[:sim_time_end]=$data['sim'].dex.count-1

        calculated_var_update_all()
    end    
    
    def sim_table()
      table = $data['sim'].sim_queue.map.with_index {|x,i| y={id:i}; y.merge(x) }
      
      if table.size > 0 then
          column = table[0].map {|k,v| k}
          return format_table(table, column)
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
                $data["sim"].change_time(new_time)
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
    $vars[:sim_time] = $data['sim'].sim_time
    $vars[:sim_time_end] = $data['sim'].sim_time_end

    # if $data["sim"].sim_data!=nil and  $data["sim"].sim_data[0]!=nil then
        # data_column = [:time,:price,:token0_amt,:token1_amt,:token0_fee,:token1_fee,:total_fee, :dex_value, :ddex_value, :cex_position, :cex_value,:value_diff,:dprice_percent,:value_diff_dex_value_percent,:cex_fee,:total_pnl,:roi_percent,:unhedged_pnl,:unhedged_roi_percent, :bot_output,:observation,:trigger,:time_buffer,:volume0,:volume1,:volume,:ul_ratio]
        
        # Element['#export_data'].html = $vars['export_data'] = format_table($data["sim"].sim_data, data_column)
        # Element['#export_data_csv'].html = $vars['export_data_csv'] = format_csv_table($data["sim"].sim_data, data_column)


    # end
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
        # if e.key=="Tab" then
        #     puts "update metric"
        #     
        #     e.prevent
        # end

    end
    
    $document.body.on (:keyup) do |e|
        $meta_down = false if e.meta?
        $shift_down = false if e.shift?
    end
end


    EOS

    RenderWrap[:load_action]=saved_sim_load_action
    RenderWrap[:sim]=sim
    RenderWrap[:pool_option] = pool_option
    RenderWrap[:pool_option_value] = pool_option_value
    RenderWrap[:out_of_service]=out_of_service
    RenderWrap.data
end


