__TASK_NAME__ = "demo/demo_factorial"
__ENV__ = 'ruby3'

def main()
    n = __n__
    
    if n.to_i==1 then
        return 1
    else
      task =Task.run_remote(_task.name,{n:n-1})
      update_task = Task.wait_until_done(task)
      return update_task.raw_ret.to_i * n
    end
end
