__TASK_NAME__ = "demo/load/demo_load_class"

load(Task.load("demo/load/demo_load_lv2::_mul"))

class Avg
    def self.call(array)
        array.sum.to_f / array.size
    end
    
end

def mul(a,b)
    _mul(a,b)
end


def main
    $logger.call (Avg.call [1,2,3,4])
    $logger.call mul(2,3)
end
