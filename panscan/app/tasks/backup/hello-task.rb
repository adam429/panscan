__TASK_NAME__ = "hello-task"

def main()
    time = Time.now()

    10.times do |i|
        _log ("the #{i} run\n")
        sleep(1)
    end
    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
