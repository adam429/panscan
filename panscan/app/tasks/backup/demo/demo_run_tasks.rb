__TASK_NAME__ = "demo/demo_run_tasks"

def main()
    remote_task = []
    
    remote_task << Task.run_remote("demo/demo_task",{count:"1"})
    remote_task << Task.run_remote("demo/demo_task",{count:"2"})
    remote_task << Task.run_remote("demo/demo_task",{count:"3"})
    
    remote_task = Task.wait_until_done(remote_task)
    remote_task.each do |task|
        $logger.call "#{task.output}""
    end
    return "done"
end
