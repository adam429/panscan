__TASK_NAME__ = "demo/demo_binding"

load(Task.load("base/logger"))

load(Task.load("base/render_wrap"))
load(Task.load("base/opal_binding"))
load(Task.load("base/widget"))

def max(a,b)
    a>b ? a : b
end

def min(a,b)
    a<b ? a : b
end

class Fibonacci < MappingObject
    attr_accessor :n

    def to_data
        self.n
    end
    
    def from_data(data)
        self.n = data.to_i
    end
    
    def fn(n)
        return 1 if n==0
        return 1 if n==1 
        return fn(n-1)+fn(n-2) 
    end
    
    def result
        fn(self.n)
    end
    
    def initialize(n)
        self.n = n
    end
        
end


def main()
    init_logger(binding)
    $task_name = _task.name
    
    RenderWrap.load(Task.load("demo/load/demo_load_sum::sum"))
    RenderWrap.load(Task.load("#{_task.name}::max"))
    RenderWrap.load(Task.load("#{_task.name}::min"))
    
    fobj = Fibonacci.new(11)
    fobj.result # ==> 144

    RenderWrap[:fobj] = fobj
    RenderWrap.data
end

def render_html()
    RenderWrap.html = 
'''
(html) data[:fobj].result = <%= data[:fobj].result %> <br/>
(js) data[:fobj].result = <span id="result"></span> <br/><br/>


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

    ret = RenderWrap.render_html(binding)
    return ret
end


def render_js_rb()
    RenderWrap.jsrb = 
'''
    Element["#result"].html = data[:fobj].result
'''
    ret = RenderWrap.render_jsrb(binding)
    return ret
end
