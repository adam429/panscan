__TASK_NAME__ = "demo/demo_compress_object"

load(Task.load("base/render_wrap"))

class StoreObj < MappingObject
    def result
        self.data[:store].to_s
    end
end

def main()
    sobj = StoreObj.new
    sobj.data[:store] = "hello world!"*10000
    $logger.call("sobj.result = #{sobj.result}") # ==> 144

    RenderWrap.html = 
'''
(html) data[:store].result = <%= data[:sobj].result %> <br/>
(js) data[:store].result = <span id="result"></span> <br/><br/>
'''

    RenderWrap.jsrb = '''
    Element["#result"].html = $data["sobj"].result
'''

    RenderWrap[:sobj] = sobj
    RenderWrap.data
end



