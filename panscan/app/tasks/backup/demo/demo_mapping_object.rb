__TASK_NAME__ = "demo/demo_mapping_object"
__ENV__ = 'ruby3'

load(Task.load("base/render_wrap"))


class Fibonacci < MappingObject
    # def self.task
    #     return "demo/demo_mapping_object"
    # end
    
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

class Foo < MappingObject
    # def self.task
    #     return "demo/demo_mapping_object"
    # end
    
    mapping_accessor :fobj
end


def main()
    fobj = Fibonacci.new
    fobj.n = 11
    $logger.call("fobj.result = #{fobj.result}") # ==> 144


    foo = Foo.new()
    foo.fobj = fobj
    $logger.call("fobj.foo.result = #{foo.fobj.result}") # ==> 144

    RenderWrap.html = 
'''
(html) data[:fobj].result = <%= data[:fobj].result %> <br/>
(js) data[:fobj].result = <span id="result1"></span> <br/><br/>

(html) data[:foo].fobj.result = <%= data[:foo].fobj.result %> <br/>
(js) data[:foo].fobj.result = <span id="result2"></span> <br/><br/>

'''

    RenderWrap.jsrb = 
'''
    $logger.call "-------------"
    $logger.call $data[:fobj].to_data
    $logger.call $data[:foo].to_data

    $logger.call $data[:fobj].class
    $logger.call $data[:foo].fobj.class
    $logger.call $data[:foo].class

    $logger.call $data[:fobj]
    $logger.call $data[:foo].fobj
    $logger.call $data[:foo]

    $logger.call $data[:fobj].n
    $logger.call $data[:foo].fobj.n

    Element["#result1"].html = $data[:fobj].result
    Element["#result2"].html = $data[:foo].fobj.result
'''

    RenderWrap[:fobj] = fobj
    RenderWrap[:foo] = foo
    RenderWrap.data
end



