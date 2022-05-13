__TASK_NAME__ = "demo/demo_5_3_state_save"
__ENV__ = 'ruby3'

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))


class StateSave < MappingObject
    mapping_accessor :n
    
    def set(n)
        self.n = n
    end
    
    def get
        self.n
    end
end


def main()
    
    obj_str = '''__obj_str__'''
    param_a = __param_a__
    param_b = __param_b__

    begin
        state = MappingObject.from_encode_str(obj_str)
    rescue =>e
        $logger.call "error #{e}"
        state = StateSave.new
    end

    RenderWrap.html = 
'''
    input: <%= text binding: :input %><br/><br/>
    0-100<%= slider min:0, max:100, value:(data[:state].get or 0), binding: :input %> 
    
    [<%= button text:"save", action:%( update_task({update_params:{obj_str:$data["state"].to_encode_str()}}) ) %>]
    <%= text binding: :status %>
    <br/><br/>
    
    obj_str = <%= text binding: :obj_str %><br/>
    obj_encode_str = <%= text binding: :obj_encode_str %><br/>

    <%= calculated_var %( $data["state"].set(:input.to_i) ) %>
    <%= calculated_var %( :obj_str = $data["state"].to_str ) %>
    <%= calculated_var %( :obj_encode_str = $data["state"].to_encode_str ) %>
'''

    RenderWrap.jsrb = 
<<~EOS
    def wait_close()
        HTTP.get "/task/json/#{$task.id}" do |res|
            if res.ok? then
                puts res.json["status"]
                if res.json["status"]=="close" then
                    $$.location.reload()
                elsif res.json["status"]=="run" or res.json["status"]=="open" then
                    $vars["status"] = "running... status: #\{res.json["status"]\}"
                    binding_update_change_all()
                    $$[:setTimeout].call(->{ wait_close() },1000)
                end
            end        
        end
    end

    def update_task(obj_str)
        puts "update_task"
        
        $vars["status"] = "running..."
        binding_update_change_all()
        HTTP.post("/task/params/#{$task.id}", payload:obj_str) do |res0|
            if res0.ok? then
                HTTP.get("/task/status/#{$task.id}/open") do |res1|
                  if res1.ok? then
                    $$[:setTimeout].call(->{ wait_close() },1000)
                  end        
                end
            end
        end
    end
EOS

    RenderWrap[:state] = state
    RenderWrap.data
end




