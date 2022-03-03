__TASK_NAME__ = "demo/load/demo_load_caller"


load(Task.load("demo/load/demo_load_sum::sum"))
load(Task.load("demo/load/demo_load_class"))

def main()
    _log sum(4,5).to_s+"\n"
    _log Avg.call([1,2,3,4]).to_s+"\n"
    _log mul(2,3).to_s+"\n"
    nil
end
