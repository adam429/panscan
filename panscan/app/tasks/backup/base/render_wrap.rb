__TASK_NAME__ = "base/render_wrap"

require 'zlib'
require 'base64'

class MappingObject
    # @@class_map = {}
    
    def self.task
        return $task.name
    end
    
    def self.mapping_accessor(*attrs)
      attrs.each do |attr|
        raise ":data is reserve word for MappingObject" if attr==:data
        define_method("#{attr}") { self.data[attr] }
        define_method("#{attr}=") { |val| self.data[attr] = val }
      end
    end    
    
    attr_accessor :data

    def initialize ()
        @data = {}
    end
    
    def to_str()
        to_json
    end
    
    def to_encode_str()
        if RUBY_ENGINE=='opal' then
            %x{
                function compress_encode(data) {
                    uint8Arr = pako.deflate(data, { to: 'string' });
                    
                    const APPLY_MAX = 4*1024;
                    var encodedStr = ''; 
                    for(var i = 0; i < uint8Arr.length; i+=APPLY_MAX){
                      encodedStr += String.fromCharCode.apply(
                        null, uint8Arr.slice(i, i+APPLY_MAX)
                      );
                    }
                    return encodedStr
                }
                Opal.global.compress_encode = compress_encode
            }
            ret = to_str()
            # $logger.call "-1--------"
            # $logger.call ret
            ret = $$.compress_encode(ret)
            # $logger.call "-2--------"
            # $logger.call ret
            ret = Base64.encode64(ret)
            # $logger.call "-3--------"
            # $logger.call ret
        else
            ret = to_str()
            ret = Zlib::Deflate.deflate(ret)
            ret = Base64.encode64(ret)
            
        end
        return ret
    end

    def self.from_encode_str(obj_str)
        if RUBY_ENGINE=='opal' then
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
            ret = $$.compress_decode(Base64.decode64(obj_str))
        else
            ret = Base64.decode64(obj_str)
            ret = Zlib::Inflate.inflate(ret)
        end
        # $logger.call "--------"
        # $logger.call ret
        self.from_str(ret)
    end
    
    def self.from_str(obj_str)
        obj_json = JSON.parse(obj_str).map {|k,v| [k.to_sym,v] }.to_h
        class_name = obj_json[:json_class]
        obj_data = obj_json[:data]

        # $logger.call "========="
        # $logger.call obj_str
        # $logger.call obj_json
        # $logger.call obj_json.class

        # $logger.call class_name
        # $logger.call obj_data

        
        obj = (Object.const_get class_name).new
        obj.from_data(obj_data)
        
        
        return obj
    end
    
    def to_json(*args)
      
      {
         JSON.create_id  => self.class.name,
         'data'          => self.to_data
      }.to_json(*args)
    end

    def to_data
        ret = @data.map do |k,v|
            if (v.class.ancestors.include? MappingObject)==false then
                [k,v]
            else
                v.class.add_class 
                [k,"(MappingObject)|||#{v.class.name}|||#{v.to_data}"]
            end
        end.to_h
        ret = JSON.dump(ret)
        ret
    end
    
    def from_data(data)
        # puts self.class
        # puts data
        begin
            data=JSON.parse(data.gsub(/Infinity/,"0").gsub(/NaN/,"0")).map {|k,v| [k.to_sym,v] }.to_h
            
            obj_data = data.map do |k,v|
                if v =~ /^\(MappingObject\)\|\|\|/ then
                    split = v.split("|||")
                    _ = split.shift
                    class_name = split.shift
                    obj_data = split.join("|||")
                    
                    obj = (Object.const_get class_name).new
                    obj.from_data(obj_data)
                    [k,obj]
                else
                    [k,v]
                end
            
            end.to_h
            
            # puts obj_data
            
            self.data = obj_data
        rescue =>e
            puts data
            raise e
        end
    end
    
    def []=(key,val)
        self.data[key] = val
    end
    
    def [](key)
        self.data[key]
    end
    
    def self.add_class
        if RUBY_ENGINE=='ruby' then                
            # $logger.call "===add class==="
            # @@class_map[self.name] = "#{$task.name}::#{self.name}"
            task = self.task
            
            # $logger.call "#{task}::#{self.name}"
            # $logger.call Task.load("#{task}::#{self.name}")
            # $logger.call open(Task.load("#{task}::#{self.name}")).read()
            
            RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
            RenderWrap.load(Task.load("#{task}::#{self.name}"))
        end
    end
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
    
    data = JSON.parse(data).map {|k,v| [k.to_sym,v] }.to_h
    ret = data.map do |k,v|
        if v =~ /^\(MappingObject\)\|\|\|/ then
            split = v.split("|||")
            _ = split.shift
            class_name = split.shift
            obj_data = split.join("|||")
            
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

    def self.to_data
        ret = self.instance.data.map do |k,v|
            if (v.class.ancestors.include? MappingObject)==false then
                [k,v]
            else
                v.class.add_class
                [k,"(MappingObject)|||#{v.class.name}|||#{v.to_data}"]
            end
        end.to_h
        
        ret = JSON.dump(ret)
    end
    
    def self.encode(input)
        if RUBY_ENGINE=='opal' then
            #opal code
        else
            ret = input
            ret = Zlib::Deflate.deflate(ret)
            ret = Base64.encode64(ret)
            return ret
        end
    end
    
    def self.decode(input)
        if RUBY_ENGINE=='opal' then
            #opal code
        else
            ret = input
            ret = Base64.decode64(ret)
            ret = Zlib::Inflate.inflate(ret)
            return ret
        end
    end
    
    def self.jsrb_data
        self.encode(self.to_data)
    end
    
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
        self.before_html_erb("data.transfer","""<% data = (@raw_ret[:data]) %>\n""")
        self.before_html_erb("data.transfer_js","""<pre id='data-transfer' style='display:none'><%= @raw_ret[:json] %></pre>\n""")
        self.load(Task.load("base/render_wrap::jsrb_undata"))
        self.before_jsrb_erb("data.transfer","""$data = jsrb_undata($document.at_css('#data-transfer').text)\n""")
        self.before_html("library.pako","<script src='https://cdn.jsdelivr.net/npm/pako@2.0.4/dist/pako.min.js'></script>")
        self.before_jsrb("library.base64","require 'base64'\n")
        self.before_jsrb_erb("logger","$logger = ->(x){ puts(x) }\n")

        ret_json = self.jsrb_data
        ret_data = self.instance.data

        return {json:ret_json,data:ret_data}
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
