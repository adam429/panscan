__TASK_NAME__ = "demo/demo_5_2_mapping_object"
__ENV__ = 'ruby3'

load(Task.load("base/render_wrap"))


class Fibonacci < MappingObject
    mapping_accessor :n
    
    def fn(n)
        return 1 if n==0
        return 1 if n==1 
        return fn(n-1)+fn(n-2) 
    end
    
    def result
        fn(self.n)
    end
end


def main()
    fobj = Fibonacci.new
    fobj.n = 11
    $logger.call("fobj.result = #{fobj.result}") # ==> 144

    RenderWrap.html = 
'''
(html) data[:fobj].result = <%= data[:fobj].result %> <br/>
(js) data[:fobj].result = <span id="result1"></span> <br/><br/>

'''

    RenderWrap.jsrb = 
'''
    Element["#result1"].html = $data[:fobj].result
'''

    RenderWrap[:fobj] = fobj
    RenderWrap.data
end



