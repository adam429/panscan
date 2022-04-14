__TASK_NAME__ = "demo/demo_chart"

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

def main()
    RenderWrap.load(Task.load("#{$task.name}::chart_data1"))
    RenderWrap.load(Task.load("#{$task.name}::chart_data2"))
        
    RenderWrap.html=
    '''
    <h1>Chart</h1>
    input: <%= text binding: :input %><br/><br/>
    0-100<%= slider min:0, max:100, value:10, binding: :input %> 
    <%= button text:"Next", action:":input = :input.to_i+1" %>
    <%= button text:"Play", action:"play()" %>
    <%= button text:"Stop", action:"stop()" %>
    
    <br/><br/>
    
    <%= calculated_var ":chart_val1 = chart_data1(:input.to_i)" %>
    <%= calculated_var ":chart_val2 = chart_data2(:input.to_i)" %>
    <%= chart binding: :chart_val1 %>
    <%= chart binding: :chart_val2 %>
    
    '''
    
    RenderWrap.jsrb=
    '''
        def stop()
            $play_flag = false
        end
        def play()
            $play_flag = true
            $$[:setTimeout].call(->{ play_callback() },100)
        end
        
        def play_callback()
            if $play_flag then
                $vars[:input]=$vars[:input].to_i+1
                $vars[:input]=0 if $vars[:input].to_i>100
                binding_update_change_all()
                calculated_var_update_all()            
                
                $$[:setTimeout].call(->{ play_callback() },100) 
            end
        end

    '''
    
    nil
end

def chart_data1(input)
    arr = (1..input).map {|x| x**2}
    
    spec = {
      "title": "A Simple Bar Chart",
      "width": 200,
      "height": 200,
      "data": {
        "values": []
      },
      "mark": "bar",
      "encoding": {
        "x": {"field": "a", "type": "ordinal"},
        "y": {"field": "b", "type": "quantitative"}
        
      }
    }
    spec["data"]["values"] = arr.map.with_index do |x,i|  {"a": i,"b": x} end

    return spec
end

def chart_data2(input)
    arr = (1..input).map {|x| x**2}
    
    spec = {
      "title": "A simple pie chart",
      "data": {
        "values": [
          {"category": 1, "value": arr.filter{|x| 0<=x and x<100}.sum },
          {"category": 2, "value": arr.filter{|x| 100<=x and x<500}.sum },
          {"category": 3, "value": arr.filter{|x| 500<=x and x<2000}.sum },
          {"category": 4, "value": arr.filter{|x| 2000<=x and x<5000}.sum },
          {"category": 5, "value": arr.filter{|x| 5000<=x and x<10000}.sum },
        ]
      },
      "mark": "arc",
      "encoding": {
        "theta": {"field": "value", "type": "quantitative"},
        "color": {"field": "category", "type": "nominal"}
      }
    }   

    return spec
end

