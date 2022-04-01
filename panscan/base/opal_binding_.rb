load(Task.load("base/render_wrap"))
class OpalBinding
  include(Singleton)

  def self.binding(name, value, widget)
    if value != nil
      self.instance.vars.[]=(name, value)
    end
    suffix_name = self.suffix(name)
    self.instance.bindings.push([name, suffix_name, widget.update_change, widget.fetch_change, widget.change_event])
    return suffix_name
  end

  def self.suffix(name)
    suffix = name.to_s + "_" + SecureRandom.hex(4)
    return suffix
  end

  def self.calculated_vars(expression)
    self.instance.calculated_vars.push(expression)
    nil
  end

  def self.define_vars(var_name, expression)
    self.instance.define_vars.[]=(var_name, expression)
    nil
  end
  attr_accessor(:bindings, :vars, :calculated_vars, :define_vars)

  def initialize
    self.bindings=[]
    self.vars={}
    self.calculated_vars=[]
    self.define_vars={}
    binding_jsrb = "" "\n$bindings = <%= OpalBinding.instance.bindings %>\n$vars = <%= OpalBinding.instance.vars %>.merge(<%= OpalBinding.instance.define_vars %>)\n\ndef binding_update_change(name)\n  $bindings.filter {|x| x[0]==name}.each do |x|\n       if x[2] == \"[chart]\" then\n           Native(`window.vegaEmbed`).call(\"#\#{x[1]}\", $vars[x[0]].to_n, {mode: \"vega-lite\"}.to_n)\n       else\n           $document[\"#\#{x[1]}\"].method(x[2]).call($vars[x[0]])\n       end\n  end\nend\n\ndef fetch_change(suffix_name)\n    x = $bindings.filter {|x| x[1]==suffix_name}.first\n    $vars[x[0]] = $document[suffix_name].method(x[3]).call()\nend\n\ndef binding_update_change_all()\n    $bindings.map {|x| x[0]}.uniq.each do |x|\n        binding_update_change(x)\n    end\nend\n\ndef calculated_var_update_all()\n    <%= OpalBinding.instance.calculated_vars.map {\n      |x| x.gsub(/:[a-zA-Z0-9_]+/) { \n        |y| \"$vars[\#{y}]\" \n      } \n    }.join(\"\\n\") %>\n    binding_update_change_all()    \nend\n\n\n## init\nbinding_update_change_all()\ncalculated_var_update_all()\n\n## binding\n\n## closure proc object\ndef on_event_proc(css_id,name)\n  proc {\n      fetch_change(css_id)\n      calculated_var_update_all()\n  }\nend\n\n## on event\n$bindings.filter {|x| x[4]!=\"\"}.each do |x|\n  name = x[0]\n  css_id = x[1]\n  change_event = x[4]\n  \n  $document[\"#\#{css_id}\"].on(change_event, &on_event_proc(css_id,name) )\n  \nend\n" ""
    RenderWrap.before_jsrb("binding", binding_jsrb)
  end
end

def calculated_var(expression)
  OpalBinding.calculated_vars(expression)
end
def var(var_name, expression)
  OpalBinding.define_vars(var_name, expression)
end