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

def text(option)
    Text.gen_html(option)
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
        option[:binding]="btn"
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
              <input type='range' min='#{option[:min]}' max='#{option[:max]}' value='#{option[:value]}' class='slider' id='#{OpalBinding.binding(option[:binding],option[:value],self)}'>
            </div>
            <br/>
        """
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
