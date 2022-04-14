__TASK_NAME__ = "zz"

require 'redis-objects'
require 'connection_pool'

def main()
    return ENV["REDIS_CONNECT_STR"]
end
