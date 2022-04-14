__TASK_NAME__ = "misc/address_stats_html_v2"

load(Task.load("base/render_wrap"))
load(Task.load("base/database"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

def main()
    database_init
    
    RenderWrap.html = 
'''
<%= button text:"reload", action:"reload()" %>
<%= text binding: :status %>
<br/><br/>

<table>
<tr>
    <th>#</th>
    <td>|</td>
    <th>address</th>
    <td>|</td>
    <th>bet_epoch_cnt</th>
    <td>|</td>
    <th>invest_cnt</th>
    <td>|</td>
    <th>bet_cnt</th>
    <td>|</td>
    <th>bet_bull_cnt</th>
    <td>|</td>
    <th>bet_bear_cnt</th>
    <td>|</td>
    <th>avg_bet_amt</th>
    <td>|</td>
    <th>avg_last_block_order</th>
    <td>|</td>
    <th>right_bet_ratio</th>
    <td>|</td>
    <th>win_bet_ratio</th>
    <td>|</td>
    <th>invest_amt</th>
    <td>|</td>
    <th>return_amt</th>
</tr>
<% data[:address_stats].each_with_index do |x,i| 
  addr = Address.find_by_addr(x[0])
  name = (addr and addr.tag) ? addr.tag : x[0]
 
%>
<tr>
    <td><%= i %></td>
    <td>|</td>
    <td><a href="/address/<%= x[0] %>"><%= name %></a></td>
    <td>|</td>
    <td><%= x[1]["bet_epoch_cnt"] %></td>
    <td>|</td>
    <td><%= x[1]["invest_cnt"] %></td>
    <td>|</td>
    <td><%= x[1]["bet_cnt"] %></td>
    <td>|</td>
    <td><%= x[1]["bet_bull_cnt"] %></td>
    <td>|</td>
    <td><%= x[1]["bet_bear_cnt"] %></td>
    <td>|</td>
    <td><%= x[1]["avg_bet_amt"].round(2) %></td>
    <td>|</td>
    <td><%= x[1]["avg_last_block_order"].round(2) %></td>
    <td>|</td>
    <td><%= x[1]["right_bet_ratio"].round(4) %></td>
    <td>|</td>
    <td><%= x[1]["win_bet_ratio"].round(4) %></td>
    <td>|</td>
    <td><%= x[1]["invest_amt"].round(2) %></td>
    <td>|</td>
    <td><%= x[1]["return_amt"].round(2) %></td>
</tr>
<% end %>
</table>
'''
    RenderWrap.jsrb = 
'''
    def wait_close()
        HTTP.get "/task/json/#{$data[:task_id]}" do |res|
            if res.ok? then
                puts res.json["status"]
                if res.json["status"]=="close" then
                    $$.location.reload()
                elsif res.json["status"]=="run" or res.json["status"]=="open" then
                    $vars["status"] = "running... status: #{res.json["status"]}"
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
        HTTP.get("/task/status/#{$data[:task_id]}/open") do |res|
          if res.ok? then
            $$[:setTimeout].call(->{ wait_close() },1000)
          end        
        end
    end
'''

    RenderWrap[:address_stats] = Cache.get("address_stats")[0,2000].sort {|x,y| x[1]["avg_last_block_order"]<=>y[1]["avg_last_block_order"]}
    RenderWrap[:task_id] = $task.id

    
    RenderWrap.data
    
end



