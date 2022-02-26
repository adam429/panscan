__TASK_NAME__ = "demo_clean_space"

    saved_constants = Object.constants
    saved_methods = Object.methods
    saved_class_variables = Object.class_variables
    saved_instance_variables = Object.instance_variables
    saved_instance_methods = Object.instance_methods

    A=1

    Object.constants.filter {|x| not saved_constants.include?(x) }.map {|x| Object.send(:remove_const, x)}

def main()
    
    # const
    

    puts A # error
end
