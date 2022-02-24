class Vault < ActiveRecord::Base
    def value=(value)
      self.value_i=value if value.class==Integer
      self.value_f=value if value.class==Float
      self.value_s=value if value.class==String
      self.value_t=value if value.class==Time or value.class==DateTime or value.class==Date
      self.value_b=value if value.class==FalseClass or value.class==TrueClass
      self.value_type = value.class.to_s
      
      if value.class==Array or value.class==Hash then
        self.value_s = JSON.dump(value) 
        self.value_type = "JSON"
      end
    end
    
    def value
      return self.value_i if self.value_type == "Integer"
      return self.value_f if self.value_type == "Float"
      return self.value_s if self.value_type == "String"
      return self.value_t if self.value_type == "Time" or self.value_type == "DateTime" or self.value_type == "Date"
      return self.value_b if self.value_type == "FalseClass" or self.value_type == "TrueClass"
      return JSON.parse(self.value_s) if self.value_type == "JSON"
    end
    
    def self.set(key,value)
      kv = Cache.find_by_key(key)
      kv = Cache.new() if kv==nil
      kv.key = key
      kv.value = value
      kv.save
      return value
    end
    
    def self.get(key)
      kv = Cache.find_by_key(key)
      return nil if kv==nil
      return kv.value
    end
  end