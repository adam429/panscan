__TASK_NAME__ = "demo/demo_task"
__ENV__ = 'ruby3'

def task(count)
    count.times do |i|
        $logger.call "the #{i} run"
        sleep(1)
    end
end

def main()
    time = Time.now()
    
    task(__count__)

    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
