__TASK_NAME__ = "base/render_wrap"

require 'zlib'
require 'base64'

class MappingObject
    def self.mapping_accessor(*attrs)
      attrs.each do |attr|
        define_method("#{attr}") { self.data[attr] }
        define_method("#{attr}=") { |val| self.data[attr] = val }
      end
    end    
    
    attr_accessor :data

    def initialize
        self.data = {}
    end
    
    def to_data
        ret = JSON.dump(self.data)
        ret
    end
    
    def from_data(data)
        self.data=JSON.parse(data)
    end
    
    def []=(key,val)
        self.data[key] = val
    end
    
    def [](key)
        self.data[key]
    end
    
    def self.add_class
        RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
        RenderWrap.load(Task.load("#{$task.name}::#{self.name}"))
    end
    
end

def html_data(data)
    data
end

def jsrb_data(data)
    RenderWrap.load(Task.load("base/render_wrap::jsrb_undata"))
    RenderWrap.before_html("library.pako","<script src='https://cdn.jsdelivr.net/npm/pako@2.0.4/dist/pako.min.js'></script>")
    RenderWrap.before_jsrb("library.base64","require 'base64'\n")
    
    non_mapping_obj =  data.filter do |k,v| (v.class.ancestors.include? MappingObject)==false end
    mapping_obj = data.filter do |k,v| v.class.ancestors.include? MappingObject end
    
    ret = data.map do |k,v|
        if (v.class.ancestors.include? MappingObject)==false then
            [k,v]
        else
            v.class.add_class
            [k,"(MappingObject)|||#{v.class.name}|||#{v.to_data}"]
        end
    end.to_h
    
    
    ret = JSON.dump(ret)
    ret = Zlib::Deflate.deflate(ret)
    ret = Base64.encode64(ret)
    ret
end

def jsrb_undata(data)
%x{
    function compress_decode(data) {
        data = data.split('').map(function(x){return x.charCodeAt(0);});
        data = new Uint8Array(data);
        uint8Arr = pako.inflate(data)

        const APPLY_MAX = 4*1024;
        var encodedStr = ''; 
        for(var i = 0; i < uint8Arr.length; i+=APPLY_MAX){
          encodedStr += String.fromCharCode.apply(
            null, uint8Arr.slice(i, i+APPLY_MAX)
          );
        }
        return encodedStr
    }
    Opal.global.compress_decode = compress_decode
}
    data = $$.compress_decode(Base64.decode64(data))
    
    data = JSON.parse(data)
    ret = data.map do |k,v|
        if v =~ /^\(MappingObject\)\|\|\|/ then
            _,class_name,obj_data = v.split("|||")
            obj = (Object.const_get class_name).new
            obj.from_data(obj_data)
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
        self.before_html_erb("data.transfer","""<% data = html_data(@raw_ret[:data]) %>\n""")
        self.before_html_erb("data.transfer_js","""<pre id='data-transfer' style='display:none'><%= @raw_ret[:json] %></pre>\n""")
        self.before_jsrb_erb("data.transfer","""$data = jsrb_undata($document.at_css('#data-transfer').text)\n""")
        
        return {json:jsrb_data(self.instance.data),data:self.instance.data}
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
        
        ret = self.instance.before_html.to_h.map {|k,v| v }.join("\n") +
        html + 
        self.instance.after_html.to_h.map {|k,v| v }.join("\n")
        
        ERB.new(ret).result(binding)
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
        
        ERB.new(ret).result(binding)
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
