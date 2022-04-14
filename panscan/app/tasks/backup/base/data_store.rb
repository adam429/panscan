__TASK_NAME__ = "base/data_store"

require 'redis-objects'
require 'connection_pool'

class DataStore
    def self.init
        Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE},:url => ENV["REDIS_CONNECT_STR"]) }
        @@redis_objects = {}
        nil
    end
    
    def self.redis_object(key)
        return @@redis_objects[key] if @@redis_objects.has_key?(key)
        $logger.call ("new")
        @@redis_objects[key] = Redis::Value.new(key,:marshal => true, :compress => true)
    end
        
    def self.get (key)
        obj = self.redis_object(key)
        obj.value
    end

    def self.set (key,value)
        obj = self.redis_object(key)
        obj.value=value
    end
    
    def self.delete (key)
        obj = self.redis_object(key)
        obj.delete
    end
end

def main()
    DataStore.init
    DataStore.get("loan_data")
end
