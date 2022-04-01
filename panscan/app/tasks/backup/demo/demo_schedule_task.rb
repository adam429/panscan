__TASK_NAME__ = "demo/demo_schedule_task"

$task.schedule_at = Time.now+60
def schedule_at()
    
end

def main()
    sleep(30)
    time = Time.now()
    return "#{time} - running"
end
