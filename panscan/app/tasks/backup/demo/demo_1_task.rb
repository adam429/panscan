__TASK_NAME__ = "demo/demo_1_task"
__ENV__ = 'aliyun'

def task(count)
    count.times do |i|
        $logger.call "the #{i} run"
        sleep(1)
    end
end

def main()
    time = Time.now()
    
    param = __count__
    
    task(param)

    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
