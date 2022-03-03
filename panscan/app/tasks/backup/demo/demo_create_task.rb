__TASK_NAME__ = "demo/demo_create_task"

load(Task.load("demo/demo_task"))


def main()
    _log "run_task_local\n"

    time = Time.now()
    task(2)
    time = Time.now-time
    _log "time: #{time}\n"
    
    
    _log "run_task_remote\n"
    time = Time.now()
    
    remote_task = Task.run_remote("demo/demo_task",{count:"2"})

    _log "is_pending: #{Task.is_pending(remote_task)}\n"
    _log "is_running: #{Task.is_running(remote_task)}\n"
    _log "is_done: #{Task.is_done(remote_task)}\n"
    _log "--wait_until_running--\n"

    remote_task = Task.wait_until_running(remote_task)

    _log "is_pending: #{Task.is_pending(remote_task)}\n"
    _log "is_running: #{Task.is_running(remote_task)}\n"
    _log "is_done: #{Task.is_done(remote_task)}\n"
    _log "--wait_until_done--\n"

    remote_task = Task.wait_until_done(remote_task)

    _log "is_pending: #{Task.is_pending(remote_task)}\n"
    _log "is_running: #{Task.is_running(remote_task)}\n"
    _log "is_done: #{Task.is_done(remote_task)}\n"
    
    _log "output: #{remote_task.output}\n"
    _log "return: #{remote_task.return}\n"

    time = Time.now-time
    _log "time: #{time}\n"

end
