__TASK_NAME__ = "base/widget"

load(Task.load("base/render_wrap"))
load(Task.load("base/opal_binding"))

class Widget
    def self.gen_html(option)
    end
    
    def self.update_change
    end
    
    def self.fetch_change
    end
    
    def self.change_event
    end
end

# widgets = [
#             {name: :trigger_position, value:0.1, min:0, max:10, step:0.1 }, 
#             {name: :adj_position_ratio, value:1, min:0, max:2, step:0.1 },
#         ]
def load_widgets(widgets,default_value={})
    # $logger.call "widgets"
    # $logger.call widgets
    # $logger.call "default_value"
    # $logger.call default_value

    default_value = {} if default_value==nil
    
    widgets.map { |w|
        val = w[:value]
        val = default_value[w[:name]] if default_value[w[:name]]
        "#{w[:name].to_s}: #{text binding: w[:name].to_sym} <br/> #{slider step:w[:step] ,min:w[:min], max:w[:max], value:val, binding: w[:name].to_sym}  #{ input value:val, binding: w[:name].to_sym} <br/> "
    }.join("<br/>")
end

def table(option)
    Table.gen_html(option)
end

def text(option)
    Text.gen_html(option)
end

def input(option)
    Input.gen_html(option)
end

def select(option)
    Select.gen_html(option)
end


def button(option)
    Button.gen_html(option)
end


def slider(option)
    Slider.gen_html(option)
end

def chart(option)
    Chart.gen_html(option)
end

def datetime(option)
    Datetime.gen_html(option)
end

def pie_chart(data,title)
    spec = {
      "title": title,
      "width": 200,
      "height": 200,
      "data": {
        "values": data
      },
      "mark": "arc",
      "encoding": {
        "theta": {"field": "value", "type": "quantitative"},
        "color": {"field": "category", "type": "nominal"}
      }
    }
end

def bar_chart(data,title)
    spec = { 
      "title": title,
      "width": 200,
      "height": 200,
      "data": {
        "values": data
      },
      "mark": "bar",
      "encoding": {
        "x": {"field": "x", "type": "ordinal"},
        "y": {"field": "y", "type": "quantitative"}
        
      }
    }
end

def line_chart(data,title)
    spec ={
          "title": title,
          "width": 200,
          "height": 200,
          "data": {
            "values": data
          },
          "mark": {
            "type": "line",
            "interpolate": "monotone"
          },
          "encoding": {
            "x": {"field": "x", "type": "quantitative"},
            "y": {"field": "y", "type": "quantitative"},
            "tooltip": [
              {"field": "x"},
              {"field": "y"}
            ]
          }
        }
end

def dist_chart(data, title, maxbins=30)
    spec = {
      "title": title,
      "data": {"values": data },
      "transform": [
        {"bin": {"maxbins": maxbins}, "field": "vals", "as": "vals_"},
        {"calculate": "round(datum.vals_*100)/100", "as": "vals_binned"}
      ],
      "width": 200,
      "height": 200,
      "layer": [
        {
          "params": [
            {"name": "brush", "select": {"type": "interval", "encodings": ["x"]}}
          ],
          "mark": "bar",
          "encoding": {
            "x": {"field": "vals_binned"},
            "y": {"aggregate": "count", "field": "vals_binned"},
            "tooltip": [
              {"field": "vals_binned"},
              {"field": "vals_binned", "aggregate": "count"}
            ],
            "opacity": {"condition": {"param": "brush", "value": 1}, "value": 0.7}
          }
        },
        {
          "transform": [{"filter": {"param": "brush"}}],
          "mark": {"type": "text", "dx": {"expr": 80}, "dy": {"expr": -80}},
          "encoding": {
            "color": {"value": "firebrick"},
            "text": {"field": "vals_binned", "aggregate": "count"}
          }
        }
      ]
    }
end

class Button < Widget
    def self.gen_html(option)
        option[:binding]=:btn
        return """
        <a href='#/' id='#{OpalBinding.binding(option[:binding],nil,self,option)}'>#{ option[:text] }</a>
        """
    end

    def self.update_change
        ""
    end
    
    def self.fetch_change
        ""
    end

    def self.change_event
        "[click]"
    end
end


class Text < Widget
    def self.gen_html(option)
        return """
        <span id='#{OpalBinding.binding(option[:binding],nil,self)}'></span>
        """
    end

    def self.update_change
        "inner_html="
    end
    
    def self.fetch_change
        "inner_html"
    end

    def self.change_event
        ""
    end
end


class Datetime < Widget
    def self.gen_html(option)
        return """
              <input type='datetime-local'  min='#{option[:min]}' max='#{option[:max]}' value='#{option[:value]}' id='#{OpalBinding.binding(option[:binding],option[:value],self)}'>
        """
    end

    def self.update_change
        "value="
    end
    
    def self.fetch_change
        "value"
    end

    def self.change_event
        "change"
    end
end


class Table < Widget

    def self.gen_html(option)
        table_loader=<<~EOS
    
        def table_loader(table)
          field = table[0].map {|k,v| k}
          ret = "<table>"
          ret = ret+"<tr>"
          field.each do |x|
            ret = ret + "<td style='white-space: nowrap;'> | #\{x\}</td>"
          end
          ret = ret+"<td> | </td></tr>"
          table.each do |row|
              ret = ret+"<tr>"
              field.each do |x|
                ret = ret + "<td style='white-space: nowrap;'> | #\{row[x].to_s\}</td>"
              end
              ret = ret+"<td> | </td></tr>"
          end
          
          ret = ret+"</table>"
        end
EOS

        RenderWrap.before_jsrb("table.javascript",table_loader)
        
        if option[:binding].class==String then
            parts = option[:binding].split("=")
            name = parts.shift
            value = parts.join("=")
            # $logger.call option[:binding]
            option[:binding] = "#{name} = table_loader(#{value})"
            # $logger.call option[:binding]
        end
        
        return """
        <div id='#{OpalBinding.binding(option[:binding],nil,self)}'></div>
        """
    end

    def self.update_change
        "inner_html="
    end
    
    def self.fetch_change
        "inner_html"
    end

    def self.change_event
        ""
    end
end



class Slider < Widget
    def self.update_change
        "value="
    end
    
    def self.fetch_change
        "value"
    end

    def self.change_event
        "input"
    end

    def self.gen_html(option)
        style_css = <<~EOS
<style>
.slidecontainer {
  width: 100%;
  display: inline-block;
}

.slider {
  -webkit-appearance: none;
  width: 100%;
  height: 15px;
  border-radius: 5px;
  background: #d3d3d3;
  outline: none;
  opacity: 0.7;
  -webkit-transition: .2s;
  transition: opacity .2s;
}

.slider:hover {
  opacity: 1;
}

.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 25px;
  height: 25px;
  border-radius: 50%;
  background: #04AA6D;
  cursor: pointer;
}

.slider::-moz-range-thumb {
  width: 25px;
  height: 25px;
  border-radius: 50%;
  background: #04AA6D;
  cursor: pointer;
}
</style>
EOS

        RenderWrap.before_html("slider.style",style_css)
        
        return """
            <div class='slidecontainer' style='width:300px'>
              <input type='range' step='#{option[:step]}' min='#{option[:min]}' max='#{option[:max]}' value='#{option[:value]}' class='slider' id='#{OpalBinding.binding(option[:binding],option[:value],self)}'>
            </div>
        """
    end
end

class Input < Widget
    def self.update_change
        "value="
    end
    
    def self.fetch_change
        "value"
    end

    def self.change_event
        "input"
    end

    def self.gen_html(option)
        return """
            <input type='text' value='#{option[:value]}' id='#{OpalBinding.binding(option[:binding],option[:value],self)}'>
        """
    end
end

class Select < Widget
    def self.update_change
        "value="
    end
    
    def self.fetch_change
        "value"
    end

    def self.change_event
        "input"
    end

    def self.gen_html(option)
        ret =  """
            <select id='#{OpalBinding.binding(option[:binding],option[:value],self)}'>
            """
            
        option[:option].each_with_index { |x,i|
            ret = ret + "<option value='#{ option[:option_value] ? option[:option_value][i] : i}'>#{x}</option>"
        }
              
        ret = ret + """
            </select>        
        """
        return ret
    end
end

class Chart < Widget
    def self.gen_html(option)
        js = '''
<script src="https://cdn.jsdelivr.net/npm/vega@5.21.0"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5.2.0"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6.20.2"></script>
'''
        obj='''
def getVegaEmbed()
  Native(`window.vegaEmbed`)
end
'''
        RenderWrap.before_html("chart.javascript",js)

        RenderWrap.before_jsrb("chart.javascript",obj)
        
        return """
        <div id='#{OpalBinding.binding(option[:binding],nil,self)}'></div>
        """
    end

    def self.update_change
        '[chart]'
    end
    
    def self.fetch_change
        "inner_html"
    end

    def self.change_event
        ""
    end
end
