__TASK_NAME__ = "base/window_array"

class WindowArray
    attr_accessor :record,:limit

    def initialize(limit=0)
        @record = []
        @limit = limit
    end

    def push(obj)
        @record.push(obj)
        @record.shift if (@record.size>@limit) and (@limit>0)
    end

    def sum
        @record.sum
    end

    def count
        @record.size
    end

    def avg
        sum.to_f / count
    end
end