__TASK_NAME__ = "demo/demo_4_1_run_tasks"
__ENV__ = 'ruby3'

def main()
    remote_task = []
    
    remote_task << Task.run_remote("demo/demo_1_task",{count:"10"},Time.at(0),$logger)
    remote_task << Task.run_remote("demo/demo_1_task",{count:"20"},Time.at(0),$logger)
    remote_task << Task.run_remote("demo/demo_1_task",{count:"30"},Time.at(0),$logger)
    
    remote_task = Task.wait_until_done(remote_task)
    remote_task.each do |task|
        $logger.call "#{task.output}"
    end
    return "done"
end
