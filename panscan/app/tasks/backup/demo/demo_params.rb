__TASK_NAME__ = "demo/demo_params"
__ENV__ = 'ruby3'

def task(count)
    count.times do |x|
        $logger.call x
        sleep(1)
    end
    return "my value"
end

def main()
    task(__count__)
end
