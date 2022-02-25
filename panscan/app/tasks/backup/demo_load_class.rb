__TASK_NAME__ = "demo_load_class"

load(Task.load("demo_load_lv2/_mul"))


class Avg
    def self.call(array)
        array.sum.to_f / array.size
    end
    
end

def mul(a,b)
    _mul(a,b)
end


def main
    _log (Avg.call [1,2,3,4]).to_s+"\n"
    _log mul(2,3).to_s+"\n"
end