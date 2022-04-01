__TASK_NAME__ = "demo/demo_binding"

load(Task.load("base/render_wrap"))
load(Task.load("base/opal_binding"))
load(Task.load("base/widget"))

def max(a,b)
    a>b ? a : b
end

def min(a,b)
    a<b ? a : b
end

def main()
    RenderWrap.html = 
'''
<%= var :base, 10000 %>

<div class="container">
    <div class="right">
        number2: <%= text binding: :number2 %><br/><br/>
        0-100<%= slider min:0, max:100, value:50, binding: :number2 %> 
        20-60<%= slider min:20, max:60, binding: :number2 %> 
    </div>
    <div class="left">
        number1: <%= text binding: :number1 %><br/><br/>
        0-100<%= slider min:0, max:100, value:50, binding: :number1 %> 
        20-60<%= slider min:20, max:60, binding: :number1 %> 
    </div>
</div>

-----------------------<br/>
base = <%= text binding: :base %>  </br>
sum = <%= text binding: :sum %><%= calculated_var ":sum = sum(:base.to_i,sum(:number1.to_i, :number2.to_i))" %></br>
min = <%= text binding: :min %><%= calculated_var ":min = min(:number1.to_i, :number2.to_i)" %></br>
max = <%= text binding: :max %><%= calculated_var ":max = max(:number1.to_i, :number2.to_i)" %></br>

<style>
.container {
   height: auto;
   overflow: hidden;
}

.right {
    width: 600px;
    float: right;
}

.left {
    float: none; /* not needed, just for clarification */
    /* the next props are meant to keep this block independent from the other floated one */
    width: auto;
    overflow: hidden;
}
</style>
'''

    RenderWrap.load(Task.load("demo/load/demo_load_sum::sum"))
    RenderWrap.load(Task.load("#{$task.name}::max"))
    RenderWrap.load(Task.load("#{$task.name}::min"))
end


