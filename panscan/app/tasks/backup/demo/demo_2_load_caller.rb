__TASK_NAME__ = "demo/demo_2_load_caller"
__ENV__ = 'aliyun'


load(Task.load("demo/load/demo_load_sum::(sum,plus)"))
load(Task.load("demo/load/demo_load_class"))

def main()
    $logger.call sum(4,5)
    $logger.call plus(4,5)
    $logger.call Avg.call([1,2,3,4])
    $logger.call mul(2,3)
    nil
end
