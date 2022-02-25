__TASK_NAME__ = "panbot_simulation_matrix_result"

Task.load("database",binding)

def main()
    task = Task.where(name:"panbot_simluation_matrix").order(updated_at: :desc).where("tid is not null").first
    result = task.raw_ret.map {|x| Task.find(x) }
    result = result.map {|x| json = JSON.parse(x.params)
       ["#{json["min_amount"]}-#{json["min_payout"]}",x.raw_ret]
    }    
    result = result.sort! {|x,y| x[0]<=>y[0] }.to_h
    json = JSON.parse(task.params)
    min_payout_arr = (json["min_payout_start"].to_f..json["min_payout_stop"].to_f).step(json["min_payout_step"].to_f).map {|x| x.round(1)}
    min_amount_arr = (json["min_amount_start"].to_f..json["min_amount_stop"].to_f).step(json["min_amount_step"].to_f).map {|x| x.round(0)}
    return {params:json,mapping:result,min_payout_arr:min_payout_arr,min_amount_arr:min_amount_arr}
end

def render_html()
'''
<%  
  mapping = @raw_ret[:mapping]
  min_payout_arr = @raw_ret[:min_payout_arr]
  min_amount_arr = @raw_ret[:min_amount_arr]
  params = @raw_ret[:params]
  fields = ["return_flow","max_retrace","return_amt","invest_cnt","avg_bet_amt","avg_last_block_order","bet_ratio","right_bet_ratio","win_bet_ratio"]
  round = [4,4,2,0,2,2,4,4,4,4]
  
  def round(value,round)
    if round==0 then
      return value
    else
      return (value.round(round).to_s + "0000")[0,round+2]
    end
  end

%>
<h1>Panbot Simulation Matrix Result</h1>
<li>bet_amount_factor = <%=params["bet_amount_factor"] %></li>
<li>bet_amount_value = <%=params["bet_amount_value"] %></li>
<li>epoch_begin = <%=params["epoch_begin"] %></li>
<li>epoch_end = <%=params["epoch_end"] %></li>
<% fields.each_with_index do |field,i| %>
<h3><%= field %></h3>
<table border="1" cellspacing="0"> 
<tr>
  <td bgcolor="LightGray"></td>
  <% min_payout_arr.each do |payout| %><td bgcolor="LightGray"><%= payout %></td> <% end %>
  </tr>
  <% min_amount_arr.each do |amount| %><tr><td bgcolor="LightGray"><%= amount %></td>
    <% min_payout_arr.each do |payout| %><td> <%= round(mapping[amount.to_s + "-" + payout.to_s][field],round[i]) %> </td> 
    <% end %>
  </tr>
  <% end %>
</table>
<% end %>
'''
end


