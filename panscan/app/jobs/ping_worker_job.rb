class PingWorkerJob < ApplicationJob
    queue_as :default
  
    def perform()        
        Task.where("name like ?","ping task%").destroy_all
        50.times {|x|
            code = <<~'TASKCODE'
            def main
                _log "ping\n"
            end
            TASKCODE
            Task.create_task("ping task-#{x}", code)
        }
        PingWorkerJob.set(wait: 3.minutes).perform_later()
    end
end