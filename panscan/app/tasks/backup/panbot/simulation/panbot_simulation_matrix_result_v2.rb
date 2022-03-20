__TASK_NAME__ = "panbot/simulation/panbot_simulation_matrix_result_v2"

load(Task.load("base/database"))

def main()
    task = Task.where(name:"panbot/simulation/panbot_simulation_matrix_v2").order(updated_at: :desc).where("tid is not null").first
    result = task.raw_ret.map {|x| Task.find(x) }
    result = result.map {|x| json = JSON.parse(x.params)
      ["#{json["min_amount"]}-#{json["min_payout"]}-#{json["bet_amount_factor"]}-#{json["bet_amount_value"]}",x.raw_ret]
    }    
    result = result.sort! {|x,y| x[0]<=>y[0] }.to_h
    json = JSON.parse(task.params)
    min_payout_arr = (json["min_payout_start"].to_f..json["min_payout_stop"].to_f).step(json["min_payout_step"].to_f).map {|x| x.round(1)}
    min_amount_arr = (json["min_amount_start"].to_f..json["min_amount_stop"].to_f).step(json["min_amount_step"].to_f).map {|x| x.round(0)}
    bet_amount_factor_arr = (json["bet_amount_factor_start"].to_f..json["bet_amount_factor_stop"].to_f).step(json["bet_amount_factor_step"].to_f).map {|x| x.round(2)}
    bet_amount_value_arr = (json["bet_amount_value_start"].to_f..json["bet_amount_value_stop"].to_f).step(json["bet_amount_value_step"].to_f).map {|x| x.round(1)}
    return {params:json,mapping:result,min_payout_arr:min_payout_arr,min_amount_arr:min_amount_arr,bet_amount_factor_arr:bet_amount_factor_arr,bet_amount_value_arr:bet_amount_value_arr}
end

def render_html()
'''
<%  
  mapping = @raw_ret[:mapping]
  min_payout_arr = @raw_ret[:min_payout_arr]
  min_amount_arr = @raw_ret[:min_amount_arr]
  bet_amount_factor_arr = @raw_ret[:bet_amount_factor_arr]
  bet_amount_value_arr = @raw_ret[:bet_amount_value_arr]
  params = @raw_ret[:params]
  fields = ["return_flow","max_retrace","return_amt","invest_cnt","avg_bet_amt","avg_last_block_order","bet_round_payout","bet_ratio","right_bet_ratio","win_bet_ratio"]
  round = [4,4,2,0,2,2,4,4,4,4,4]
  
  def round(value,round)
    if round==0 then
      return value
    else
      return (value.round(round).to_s + "0000")[0,round+2]
    end
  end
  
  x_row = __x_row__
  y_row = __y_row__
  
  def gen_map_index(min_payout_arr,min_amount_arr,bet_amount_factor_arr,bet_amount_value_arr,x_row,y_row,x,y)
    min_payout = min_payout_arr.size==1 ? min_payout_arr.first : nil
    min_amount = min_amount_arr.size==1 ? min_amount_arr.first : nil
    bet_amount_factor = bet_amount_factor_arr.size==1 ? bet_amount_factor_arr.first : nil
    bet_amount_value = bet_amount_value_arr.size==1 ? bet_amount_value_arr.first : nil    
    
    name_map = {:min_payout=>min_payout_arr,:min_amount=>min_amount_arr,:bet_amount_factor=>bet_amount_factor_arr,:bet_amount_value=>bet_amount_value_arr}
    x_name = name_map.filter {|k,v| v==x_row}.to_a[0][0]
    y_name = name_map.filter {|k,v| v==y_row}.to_a[0][0]
    eval "#{x_name} = #{x}"
    eval "#{y_name} = #{y}"
    
    "#{min_amount}-#{min_payout}-#{bet_amount_factor}-#{bet_amount_value}"
  end

%>
<h1>Panbot Simulation Matrix Result</h1>
<li>min_payout = <%= min_payout_arr.size==1 ? min_payout_arr.first : "(many)" %></li>
<li>min_amount = <%= min_amount_arr.size==1 ? min_amount_arr.first : "(many)" %></li>
<li>bet_amount_factor = <%= bet_amount_factor_arr.size==1 ? bet_amount_factor_arr.first : "(many)" %></li>
<li>bet_amount_value = <%= bet_amount_value_arr.size==1 ? bet_amount_value_arr.first : "(many)" %></li>
<li>epoch_begin = <%=params["epoch_begin"] %></li>
<li>epoch_end = <%=params["epoch_end"] %></li>
<% fields.each_with_index do |field,i| %>
<h3><%= field %></h3>
<table border="1" cellspacing="0"> 
<tr>
  <td bgcolor="LightGray"></td>
  <% x_row.each do |x| %><td bgcolor="LightGray"><%= x %></td> <% end %>
  </tr>
  <% y_row.each do |y| %><tr><td bgcolor="LightGray"><%= y %></td>
    <% x_row.each do |x| %><td> <%= round(mapping[gen_map_index(min_payout_arr,min_amount_arr,bet_amount_factor_arr,bet_amount_value_arr,x_row,y_row,x,y)][field],round[i]) %> </td> 
    <% end %>
  </tr>
  <% end %>
</table>
<% end %>
'''
end


