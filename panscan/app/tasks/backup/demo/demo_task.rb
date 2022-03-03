__TASK_NAME__ = "demo/demo_task"

def task(count)
    count.times do |i|
        _log ("the #{i} run\n")
        sleep(1)
    end
end

def main()
    time = Time.now()
    
    task(__count__)

    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
