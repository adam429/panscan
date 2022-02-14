class Log < ActiveRecord::Base
    def self.log(message)
        log = Log.new
        log.pid = Process.pid
        log.runner = ENV["RUNNER_NAME"] if ENV["RUNNER_NAME"]
        log.log = message
        log.save
    end    
end