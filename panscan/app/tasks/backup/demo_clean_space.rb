__TASK_NAME__ = "demo_clean_space"

    saved_constants = self.class.constants
    saved_methods = self.class.methods
    saved_class_variables = self.class.class_variables
    saved_instance_variables = self.class.instance_variables
    saved_instance_methods = self.class.instance_methods
    
    _log(saved_constants.to_s+"\n")

    CONST=1
    class A
        def b
        end
    end

    _log(self.class.constants.to_s+"\n")


    self.constants.filter {|x| not saved_constants.include?(x) }.map {|x| Object.send(:remove_const, x); _log x.to_s+"\n"}

def main()
    
    # const
    _log CONST.to_s+"\n" # error
end
