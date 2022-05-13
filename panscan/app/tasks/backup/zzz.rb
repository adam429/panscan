__TASK_NAME__ = "zzz"
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
