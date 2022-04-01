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
def slider(option)
  Slider.gen_html(option)
end
def chart(option)
  Chart.gen_html(option)
end
class Text < Widget
  def self.gen_html(option)
    return "" "\n        <span id='#{OpalBinding.binding(option.[](:binding), nil, self)}'></span>\n        " ""
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
    style_css = "<style>\n" ".slidecontainer {\n" "  width: 100%;\n" "}\n" "\n" ".slider {\n" "  -webkit-appearance: none;\n" "  width: 100%;\n" "  height: 15px;\n" "  border-radius: 5px;\n" "  background: #d3d3d3;\n" "  outline: none;\n" "  opacity: 0.7;\n" "  -webkit-transition: .2s;\n" "  transition: opacity .2s;\n" "}\n" "\n" ".slider:hover {\n" "  opacity: 1;\n" "}\n" "\n" ".slider::-webkit-slider-thumb {\n" "  -webkit-appearance: none;\n" "  appearance: none;\n" "  width: 25px;\n" "  height: 25px;\n" "  border-radius: 50%;\n" "  background: #04AA6D;\n" "  cursor: pointer;\n" "}\n" "\n" ".slider::-moz-range-thumb {\n" "  width: 25px;\n" "  height: 25px;\n" "  border-radius: 50%;\n" "  background: #04AA6D;\n" "  cursor: pointer;\n" "}\n" "</style>\n"
    RenderWrap.before_html("slider.style", style_css)
    return "" "\n            <div class='slidecontainer' style='width:300px'>\n              <input type='range' min='#{option.[](:min)}' max='#{option.[](:max)}' value='#{option.[](:value)}' class='slider' id='#{OpalBinding.binding(option.[](:binding), option.[](:value), self)}'>\n            </div>\n            <br/>\n        " ""
  end
end

class Chart < Widget
  def self.gen_html(option)
    js = "" "\n<script src=\"https://cdn.jsdelivr.net/npm/vega@5.21.0\"></script>\n<script src=\"https://cdn.jsdelivr.net/npm/vega-lite@5.2.0\"></script>\n<script src=\"https://cdn.jsdelivr.net/npm/vega-embed@6.20.2\"></script>\n" ""
    obj = "" "\ndef getVegaEmbed()\n  Native(`window.vegaEmbed`)\nend\n" ""
    RenderWrap.before_html("chart.javascript", js)
    RenderWrap.before_jsrb("chart.javascript", obj)
    return "" "\n        <div id='#{OpalBinding.binding(option.[](:binding), nil, self)}'></div>\n        " ""
  end

  def self.update_change
    "[chart]"
  end

  def self.fetch_change
    "inner_html"
  end

  def self.change_event
    ""
  end
end
