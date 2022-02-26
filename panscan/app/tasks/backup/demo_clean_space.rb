__TASK_NAME__ = "demo_clean_space"

    saved_constants = Object.constants
    saved_methods = Object.methods
    saved_class_variables = Object.class_variables
    saved_instance_variables = Object.instance_variables
    saved_instance_methods = Object.instance_methods
    
    _log(saved_methods.to_s+"\n")

    CONST=1

    Object.constants.filter {|x| not saved_constants.include?(x) }.map {|x| Object.send(:remove_const, x); _log x.to_s+"\n"}

def main()
    
    # const
    _log CONST.to_s+"\n" # error
end
