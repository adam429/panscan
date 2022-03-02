class StartWorkerJob < ApplicationJob
    queue_as :default
  
    def perform(worker_number)
      puts "==start #{worker_number} worker"

      worker = Worker.new
      worker.create_instances(worker_number)    
    end
end