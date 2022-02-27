__TASK_NAME__ = "foo"

require 'parallel'
require 'resolv-replace'

load(Task.load("database"))
load(Task.load("pancake_prediction"))
load(Task.load("auto-retry"))

def main
    class_eval
    code = "class << Object \n remove_method :class_eval\n end"
    _log code+"\n"
   eval(code)
   
end