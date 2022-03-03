__TASK_NAME__ = "demo/demo_task"

def task(count)
    __count__.times do |i|
        _log ("the #{i} run\n")
        sleep(1)
    end
end

def main()
    time = Time.now()

    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
