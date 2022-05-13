__TASK_NAME__ = "base/opal_binding"

load(Task.load("base/render_wrap"))


class OpalBinding
    include Singleton

    def self.binding(name,value,widget,option={})
        
        if name.class==Symbol then
            self.instance.vars[name] = value if value!=nil
            
            suffix_name = self.suffix(name)
            
            self.instance.bindings.push [name,suffix_name,widget.update_change,widget.fetch_change,widget.change_event,option]
    
            return suffix_name
        end

        if name.class==String then
            # inline calculation
            parts = name.split("=")
            new_name = parts.shift
            new_name = eval(new_name)
            express = parts.join("=")
    
            self.define_calc_vars(new_name,express)
            self.binding(new_name,value,widget,option)
        end
    end
    
    def self.suffix(name)
        suffix = name.to_s + "_" + SecureRandom.hex(4)
        return suffix
    end
    
    def self.calculated_vars(expression)
        var_name = self.suffix("__anonymous__")
        self.instance.calculated_vars[var_name] = expression
        nil
    end
    
    def self.define_calc_vars(var_name,expression)
        self.instance.calculated_vars[var_name] = expression
        nil
    end
    
    def self.define_vars(var_name,expression)
        self.instance.define_vars[var_name] = expression
        nil
    end
    
    attr_accessor :bindings, :vars, :calculated_vars, :define_vars
    
    def initialize
        self.bindings = [] 
        self.vars = {}
        self.calculated_vars = {}
        self.define_vars = {}

        binding_jsrb = 
'''
$bindings = <%= OpalBinding.instance.bindings %>
$vars = <%= OpalBinding.instance.vars %>.merge(<%= OpalBinding.instance.define_vars %>)

## binding

## closure proc object
def on_change_event_proc(css_id,name)
  proc {
      fetch_change(css_id)
      calculated_var_update_all()
  }
end

<% OpalBinding.instance.bindings.filter {|x| x[4]=="[click]"}.each do |x| %>

    def on_click_event_proc_<%= x[1] %>()
      proc {
          # action
          <%= x[5][:action].gsub(/:[a-zA-Z0-9_]+/) { |y| "$vars[#{y}]" }  %>

          calculated_var_update_all()
      }
    end
    
    $document["#<%= x[1] %>"].on("click", &on_click_event_proc_<%= x[1] %>() )

<% end %>


## on event
$bindings.filter {|x| x[4]!=""}.each do |x|
  name = x[0]
  css_id = x[1]
  change_event = x[4]
  
  if change_event!="[click]" then
      $document["##{css_id}"].on(change_event, &on_change_event_proc(css_id,name) ) if change_event!=nil and change_event!=""
  end
  
end
'''        
        RenderWrap.before_jsrb("binding",binding_jsrb)
        
        binding_jsrb = 
'''
def binding_update_change(name,option={})
  $bindings.filter {|x| x[0]==name}.each do |x|
    #   puts "--update_change--#{x}--"
       if x[2] == "[chart]" then
          if not(option[:exclude]=="chart") then
            Native(`window.vegaEmbed`).call("##{x[1]}", $vars[x[0]].to_n, {mode: "vega-lite"}.to_n)
          end
      else
          $document["##{x[1]}"].method(x[2]).call($vars[x[0]]) if x[2]!=nil and x[2]!=""
      end
  end
end

def fetch_change(suffix_name)
    x = $bindings.filter {|x| x[1]==suffix_name}.first
    $vars[x[0]] = $document[suffix_name].method(x[3]).call()  if x[3]!=nil and x[3]!=""
end

def binding_update_change_all(option={})
    $bindings.map {|x| x[0]}.uniq.each do |x|
        binding_update_change(x,option)
    end
end

def calculated_var_update_all(option={:exclude=>"chart"})
    <%= OpalBinding.instance.calculated_vars.map { |k,v|
        x = ":"+k.to_s+" = "+v.to_s
        x=x.gsub(/:[a-zA-Z0-9_]+/) { 
            |y| "$vars[#{y}]" 
        }
        
        x = """
            if option[:exclude]==\"chart\" and $bindings.filter {|x| x[0]==:#{k.to_s} and x[2]==\"[chart]\" }.size>0 then
                # skip chart binding widget calc_var
            else
                #{x}
            end
        """
        # $logger.call x
        x
    }.join("\n") %>
    binding_update_change_all(option)    
end

## init
$document.ready do    
    calculated_var_update_all({:exclude=>nil})
end

'''
        RenderWrap.after_jsrb("binding",binding_jsrb)

    end
end

def calculated_var(expression)
    OpalBinding.calculated_vars(expression)
end

def calc_var(var_name,expression)
    OpalBinding.define_calc_vars(var_name,expression)
end

def var(var_name,expression)
    OpalBinding.define_vars(var_name,expression)
end
