__TASK_NAME__ = "demo/other/demo_concurrent_limit"
__ENV__ = 'ruby3'

load(Task.load("demo/demo_task"))

def concurrent_limit(queue,limit=8)
    loop do
        queue_count = Task.where(id: queue.map {|x| x.id}).where("status='run' or status='open'").count
        if queue_count<limit then
            yield
            return
        end
        sleep 1 
    end
end


def main()
    remote_task = []

    _log ("==no limit==\n")
    12.times do |i|
        remote_task = Task.run_remote("demo/demo_task",{count:"5"})
        _log "#{Time.now} - #{i} task start\n"
    end

    remote_task = Task.wait_until_done(remote_task)

    remote_task = []
    _log ("==concurrent limit==\n")
    12.times do |i|
        concurrent_limit(remote_task) {
            remote_task << Task.run_remote("demo/demo_task",{count:"5"})
        }
        _log "#{Time.now} - #{i} task start\n"
    end

    remote_task = Task.wait_until_done(remote_task)
    
    nil

end
