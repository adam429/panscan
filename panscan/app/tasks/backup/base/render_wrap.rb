__TASK_NAME__ = "base/render_wrap"

class MappingObject
    def self.add_class
        RenderWrap.load(Task.load("base/render_wrap::jsrb_undata"))
        RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
        RenderWrap.load(Task.load("#{$task_name}::#{self.name}"))
    end
    
    def to_data
    end
end

def html_data(data)
    data
end

def jsrb_data(data)
    non_mapping_obj =  data.filter do |k,v| (v.class.ancestors.include? MappingObject)==false end
    mapping_obj = data.filter do |k,v| v.class.ancestors.include? MappingObject end
    
    ret = data.map do |k,v|
        if (v.class.ancestors.include? MappingObject)==false then
            [k,v]
        else
            [k,"(MappingObject)|||#{v.class.name}|||#{v.to_data}"]
        end
    end.to_h
end

def jsrb_undata(data)
    ret = data.map do |k,v|
        if v =~ /^\(MappingObject\)\|\|\|/ then
            _,class_name,data = v.split("|||")
            obj = (Object.const_get class_name).new
            obj.from_data(data)
            [k,obj]
        else
            [k,v]
        end
        
        
    end.to_h
end


class RenderWrap
    include Singleton
    
    attr_accessor :html, :jsrb, :data
    attr_accessor :before_html, :after_html, :before_jsrb, :after_jsrb
    attr_accessor :before_html_erb, :after_html_erb, :before_jsrb_erb, :after_jsrb_erb
    
    def initialize
        self.html = ""
        self.jsrb = ""
        self.before_html = []
        self.after_html = []
        self.before_jsrb = []
        self.after_jsrb = []
        self.before_html_erb = []
        self.after_html_erb = []
        self.before_jsrb_erb = []
        self.after_jsrb_erb = []
        self.data = {}
    end
    
    def self.load(file)
        src=File.read(file)
        self.before_jsrb(file,src)
    end
    
    def self.data
        self.before_html_erb("data.transfer","""<% data = html_data(@raw_ret) %>\n""")
        self.before_jsrb_erb("data.transfer","""data =  jsrb_undata(<%= jsrb_data(@raw_ret) %>) \n""")
        
        non_mapping_obj = self.instance.data.filter do |k,v| (v.class.ancestors.include? MappingObject)==false end
        mapping_obj = self.instance.data.filter do |k,v| v.class.ancestors.include? MappingObject end
        
        mapping_obj.map do |k,v| 
            v.class.add_class
        end

        return self.instance.data 
    end
    
    def self.[]=(key,val)
        self.instance.data[key] = val
    end
    
    def self.[](key)
        self.instance.data[key]
    end
    
    
    def self.html=(val)
        self.instance.html = val
    end

    def self.jsrb=(val)
        self.instance.jsrb = val
    end
    
    def self.render_html(binding)
        html = ERB.new(
            self.instance.before_html_erb.to_h.map {|k,v| v }.join("\n") +
            self.instance.html +
            self.instance.after_html_erb.to_h.map {|k,v| v }.join("\n")
        ).result(binding)
        
        self.instance.before_html.to_h.map {|k,v| v }.join("\n") +
        html + 
        self.instance.after_html.to_h.map {|k,v| v }.join("\n")
    end

    def self.render_jsrb(binding)
        jsrb = ERB.new(
            self.instance.before_jsrb_erb.to_h.map {|k,v| v }.join("\n") +
            self.instance.jsrb +
            self.instance.after_jsrb_erb.to_h.map {|k,v| v }.join("\n")
        ).result(binding)

        ret = self.instance.before_jsrb.to_h.map {|k,v| v }.join("\n") +
        jsrb + 
        self.instance.after_jsrb.to_h.map {|k,v| v }.join("\n")
        
        return ret

    end
    
    def self.before_html(id,val)
        self.instance.before_html.push [id,val] if id==nil
        self.instance.before_html.push [id,val] if id!=nil and not self.instance.before_html.to_h.has_key?(id)
    end

    def self.after_html(id,val)
        self.instance.after_html.push [id,val] if id==nil
        self.instance.after_html.push [id,val] if id!=nil and not self.instance.after_html.to_h.has_key?(id)
    end
    
    def self.before_jsrb(id,val)
        self.instance.before_jsrb.push [id,val] if id==nil
        self.instance.before_jsrb.push [id,val] if id!=nil and not self.instance.before_jsrb.to_h.has_key?(id)
    end

    def self.after_jsrb(id,val)
        self.instance.after_jsrb.push [id,val] if id==nil
        self.instance.after_jsrb.push [id,val] if id!=nil and not self.instance.after_jsrb.to_h.has_key?(id)
    end

    def self.before_html_erb(id,val)
        self.instance.before_html_erb.push [id,val] if id==nil
        self.instance.before_html_erb.push [id,val] if id!=nil and not self.instance.before_html_erb.to_h.has_key?(id)
    end

    def self.after_html_erb(id,val)
        self.instance.after_html_erb.push [id,val] if id==nil
        self.instance.after_html_erb.push [id,val] if id!=nil and not self.instance.after_html_erb.to_h.has_key?(id)
    end
    
    def self.before_jsrb_erb(id,val)
        self.instance.before_jsrb_erb.push [id,val] if id==nil
        self.instance.before_jsrb_erb.push [id,val] if id!=nil and not self.instance.before_jsrb_erb.to_h.has_key?(id)
    end

    def self.after_jsrb_erb(id,val)
        self.instance.after_jsrb_erb.push [id,val] if id==nil
        self.instance.after_jsrb_erb.push [id,val] if id!=nil and not self.instance.after_jsrb_erb.to_h.has_key?(id)
    end

end
