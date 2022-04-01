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

def slider(option)
    Slider.gen_html(option)
end

def chart(option)
    Chart.gen_html(option)
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
