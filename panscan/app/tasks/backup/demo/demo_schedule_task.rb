__TASK_NAME__ = "demo/demo_schedule_task"

def schedule_at()
    Time.now+60
end

def main()
    sleep(30)
    time = Time.now()
    return "#{time} - running"
end
