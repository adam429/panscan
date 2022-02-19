class Log < ActiveRecord::Base
    def self.log(message)
        log = Log.new
        log.pid = Process.pid
        log.hostname = Socket.gethostname
        log.ip_addr = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
        log.worker = ENV["WORKER_NAME"] if ENV["WORKER_NAME"]
        log.log = message
        log.save
    end    
end