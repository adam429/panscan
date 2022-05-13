__TASK_NAME__ = "demo/other/demo_task_runner"
__ENV__ = 'ruby3'

def main
    $logger.call "my runner is #{$task.runner}"
    $logger.call "#{RUBY_VERSION}"
end