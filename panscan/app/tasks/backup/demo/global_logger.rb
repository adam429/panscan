__TASK_NAME__ = "demo/global_logger"

# load(Task.load("base/logger"))

def main
    # init_logger(binding)
    
    $logger.call ($task.name)
    
end