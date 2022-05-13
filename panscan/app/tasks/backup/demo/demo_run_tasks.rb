__TASK_NAME__ = "demo/demo_run_tasks"
__ENV__ = 'ruby3'

def main()
    remote_task = []
    
    remote_task << Task.run_remote("demo/demo_task",{count:"1"},Time.at(0),$logger)
    remote_task << Task.run_remote("demo/demo_task",{count:"2"},Time.at(0),$logger)
    remote_task << Task.run_remote("demo/demo_task",{count:"3"},Time.at(0),$logger)
    
    remote_task = Task.wait_until_done(remote_task)
    remote_task.each do |task|
        $logger.call "#{task.output}"
    end
    return "done"
end
