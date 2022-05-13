__TASK_NAME__ = "demo/demo_auto_split"
__ENV__ = 'ruby3'

load(Task.load("base/auto_split"))

def main()
    time = Time.now()
    
    begin_param = __begin_param__    
    end_param = __end_param__    
    step = 20

    # map stage
    ret = auto_split_remote_task(begin_param,end_param,step) do |begin_param,end_param|
        
        (begin_param..end_param).map {|x| x }.sum
    end
    
    # reduce stage
    ret = ret.sum if ret.class==Array

    time = Time.now()-time
    
    return ret

end
