class StartWorkerJob < ApplicationJob
    queue_as :default
  
    def perform(worker_number)
      puts "==start #{worker_number} worker"
    end
end