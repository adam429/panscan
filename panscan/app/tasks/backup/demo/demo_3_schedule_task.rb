__TASK_NAME__ = "demo/demo_3_schedule_task"
__ENV__ = 'aliyun'


$task.next_schedule_at = Time.now+60

def main()
    sleep(30)
    time = Time.now()
    return "#{time} - running"
end
