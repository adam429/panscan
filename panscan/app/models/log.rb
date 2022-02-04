class Log < ActiveRecord::Base
    def self.log(message)
        log = Log.new
        log.pid = Process.pid
        log.log = message
        log.save
    end    
end