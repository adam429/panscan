__TASK_NAME__ = "demo/demo-task"

def main()
    time = Time.now()

    __count__.times do |i|
        _log ("the #{i} run\n")
        sleep(1)
    end
    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
