__TASK_NAME__ = "demo/demo_schedule_task"
__ENV__ = 'ruby3'

$task.next_schedule_at = Time.now+60

def main()
    sleep(30)
    time = Time.now()
    return "#{time} - running"
end
