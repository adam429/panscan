__TASK_NAME__ = "base/opal_binding"

load(Task.load("base/render_wrap"))


class OpalBinding
    include Singleton

    def self.binding(name,value,widget)

        self.instance.vars[name] = value if value!=nil
        
        suffix_name = self.suffix(name)
        
        self.instance.bindings.push [name,suffix_name,widget.update_change,widget.fetch_change,widget.change_event]

        return suffix_name
    end
    
    def self.suffix(name)
        suffix = name.to_s + "_" + SecureRandom.hex(4)
        return suffix
    end
    
    def self.calculated_vars(expression)
        self.instance.calculated_vars.push expression
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
        self.calculated_vars = []
        self.define_vars = {}

        binding_jsrb = 
'''
$bindings = <%= OpalBinding.instance.bindings %>
$vars = <%= OpalBinding.instance.vars %>.merge(<%= OpalBinding.instance.define_vars %>)

def binding_update_change(name)
  $bindings.filter {|x| x[0]==name}.each do |x|
       if x[2] == "[chart]" then
           Native(`window.vegaEmbed`).call("##{x[1]}", $vars[x[0]].to_n, {mode: "vega-lite"}.to_n)
       else
           $document["##{x[1]}"].method(x[2]).call($vars[x[0]])
       end
  end
end

def fetch_change(suffix_name)
    x = $bindings.filter {|x| x[1]==suffix_name}.first
    $vars[x[0]] = $document[suffix_name].method(x[3]).call()
end

def binding_update_change_all()
    $bindings.map {|x| x[0]}.uniq.each do |x|
        binding_update_change(x)
    end
end

def calculated_var_update_all()
    <%= OpalBinding.instance.calculated_vars.map {
      |x| x.gsub(/:[a-zA-Z0-9_]+/) { 
        |y| "$vars[#{y}]" 
      } 
    }.join("\n") %>
    binding_update_change_all()    
end


## init
binding_update_change_all()
calculated_var_update_all()

## binding

## closure proc object
def on_event_proc(css_id,name)
  proc {
      fetch_change(css_id)
      calculated_var_update_all()
  }
end

## on event
$bindings.filter {|x| x[4]!=""}.each do |x|
  name = x[0]
  css_id = x[1]
  change_event = x[4]
  
  $document["##{css_id}"].on(change_event, &on_event_proc(css_id,name) )
  
end
'''        
        RenderWrap.before_jsrb("binding",binding_jsrb)
    end
end

def calculated_var(expression)
    OpalBinding.calculated_vars(expression)
end

def var(var_name,expression)
    OpalBinding.define_vars(var_name,expression)
end
