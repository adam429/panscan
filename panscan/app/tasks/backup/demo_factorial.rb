__TASK_NAME__ = "demo_factorial"


def main()
    n = __n__

    return Task.run_remote(demo_factorial,{n:"1"})    
    # if n==1 then
    #     return "1"
    # else
    #     return n*(Task.run_remote(demo_factorial,{n:"#{n-1}"})).to_i
    # end
end
