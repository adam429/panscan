__TASK_NAME__ = "demo/demo_mapping_object"

load(Task.load("base/logger"))

load(Task.load("base/render_wrap"))
load(Task.load("base/opal_binding"))
load(Task.load("base/widget"))


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

    fobj = Fibonacci.new(11)
    $logger.call(fobj.result) # ==> 144

    RenderWrap[:fobj] = fobj
    RenderWrap.data
end

def render_js_rb()
    RenderWrap.jsrb = 
'''
    Element["#result"].html = data[:fobj].result
'''
    ret = RenderWrap.render_jsrb(binding)
    return ret
end


def render_html()
    RenderWrap.html = 
'''
(html) data[:fobj].result = <%= data[:fobj].result %> <br/>
(js) data[:fobj].result = <span id="result"></span> <br/><br/>
'''

    ret = RenderWrap.render_html(binding)
    return ret
end


