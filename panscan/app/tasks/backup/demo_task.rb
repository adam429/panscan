__TASK_NAME__ = "demo_task"

def task(count)
    count.times do |x|
        _log x.to_s+"\n"
        sleep(1)
    end
    return "my value"
end

def main()
    task(__count__)
end
