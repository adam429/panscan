__TASK_NAME__ = "demo/demo_self_task"

def main()
    $logger.call $task.tid
    $logger.call $task.name
    $logger.call $task.runner
end
