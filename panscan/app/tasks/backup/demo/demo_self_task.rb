__TASK_NAME__ = "demo/demo_self_task"
__ENV__ = 'ruby3'

def main()
    $logger.call $task.tid
    $logger.call $task.name
    $logger.call $task.runner
end
