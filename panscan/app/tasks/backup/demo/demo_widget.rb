__TASK_NAME__ = "demo/demo_widget"
__ENV__ = 'ruby3'


load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))


def main()

    RenderWrap.html=
    '''
    <h1>Widget</h1>
    input: <%= text binding: :input %><br/><br/>
    0-100<%= slider min:0, max:100, value:10, binding: :input %><%= input value:"hello world", binding: :input  %>
    <br/><br/>
    
 
    <%= button text:"move to first", action:" :input = 0" %>
    <%= button text:"move to last", action:" :input = 100" %>
    <br/><br/>

    <%= select binding: :input, :option=>["First","Second","Third"],:optbinding_update_change_chartion_value=>[1,2,3], :value=>3  %>
    
    <br/>------------------------------------<br/>
    
    <% widgets = [
            {name: :trigger_position, value:0.1, min:0, max:10, step:0.1 }, 
            {name: :adj_position_ratio, value:1, min:0, max:2, step:0.1 },
        ]
    %>
    
    <%= load_widgets(widgets) %>
    <br/>------------------------------------<br/>
    
    <%= datetime min:"2018-06-01T19:30", max:"2018-06-30T19:30", value:"2018-06-12T19:30", binding: :date %>
    <%= text binding: :date %>
    '''
    
    RenderWrap.jsrb=
    '''
    '''
end

    # <%= datetime_select binding: :datetime  %>

