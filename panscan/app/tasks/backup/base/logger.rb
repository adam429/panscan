__TASK_NAME__ = "base/logger"

def init_logger(binding)
    eval('$logger =  lambda {|x| _log(x.to_s+"\n")}',binding)
end
