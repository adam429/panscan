__TASK_NAME__ = "test"

load(Task.load("base/logger"))

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

def main()
    init_logger(binding)

    RenderWrap.load(Task.load("#{_task.name}::chart_data"))
end

def chart_data(input)
    arr = (1..input).map {|x| x**2}
    
    spec = {
      "title": "A Simple Bar Chart",
      "description": "A simple bar chart with embedded data.",
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

# todo
# 1 - title of chart
# 2 - first time run - expcetion


def render_html()
    html = '''
<script src="https://cdn.jsdelivr.net/npm/vega@5.22.0"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5.2.0"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6.20.8"></script>

    <div id="vis" style="padding:50px;margin:50px"></div>

<script>
      var vlSpec = {
  "title": "this is my title",
  "data": {
    "values": [
      {"a": "C", "b": 2},
      {"a": "C", "b": 7},
      {"a": "C", "b": 4},
      {"a": "D", "b": 1}
    ]
  },
  "mark": "bar",
  "encoding": {
    "y": {"field": "a", "type": "nominal"},
    "x": {
      "aggregate": "average",
      "field": "b",
      "type": "quantitative",
      "axis": {"title": "Average of b"}
    }
  }
};

      vegaEmbed("#vis", vlSpec,{mode: "vega-lite"}).then(console.log).catch(console.warn);
    </script>
    '''
    
# '''
# <h1>Bar Chart</h1>
# input: <%= text binding: :input %><br/><br/>
# 0-100<%= slider min:0, max:100, value:10, binding: :input %> 

# <%= calculated_var ":chart_val1 = chart_data(:input.to_i)" %>
# <%= calculated_var ":chart_val2 = chart_data(:input.to_i)" %>
# <%= chart binding: :chart_val1 %>
# <%= chart binding: :chart_val2 %>

# '''
#     ret = RenderWrap.render_html(binding)
#     return ret
end


def render_js_rb()
    RenderWrap.jsrb = 
'''
'''
    ret = RenderWrap.render_jsrb(binding)
    return ret
end


