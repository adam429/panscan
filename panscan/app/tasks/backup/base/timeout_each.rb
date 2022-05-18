__TASK_NAME__ = "base/timeout_each"

load(Task.load("base/render_wrap"))


def timeout_each(arr,cp,block,timeout=1,after=nil)
    if RUBY_ENGINE == 'opal' then
        $$[:setTimeout].call(->{ 
            block.call(arr[cp])
            cp=cp+1
            if arr.size>cp
                timeout_each(arr,cp,block,timeout,after) 
            else
                after.call if after!=nil
            end
        },timeout)    
    else
        block.call(arr[cp]) # yeild arr[cp]
        cp=cp+1
        if arr.size>cp
            sleep(timeout.to_f/1000)
            timeout_each(arr,cp,block,timeout,after) 
        else
            after.call if after!=nil
        end
    end
end

def main
    timeout_each([1,2,3,4],0,->(x) { $logger.call x },1000,-> { $logger.call "done" })
    RenderWrap.load(Task.load("base/timeout_each::timeout_each"))
    
    RenderWrap.jsrb= 
'''
    timeout_each([1,2,3,4],0,->(x) { $logger.call x },1000,-> { $logger.call "done" })
'''
end
