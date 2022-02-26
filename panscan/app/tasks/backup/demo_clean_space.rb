__TASK_NAME__ = "demo_clean_space"

    saved_constants = self.class.constants
    saved_methods = self.class.methods
    saved_class_variables = self.class.class_variables
    saved_instance_variables = self.class.instance_variables

    saved_instance_methods = self.class.instance_methods
    

    CONST=1
    
    class A
    end
    
    module B
    end
    
    def foo
    end
    
    @var1 = 1
    @@var2 = 2
    
    

    self.class.constants.filter {|x| not saved_constants.include?(x) }.map {|x| self.class.send(:remove_const, x); _log x.to_s+"\n"}
    self.class.methods.filter {|x| not saved_methods.include?(x) }.map {|x| self.class.remove_method(x); _log x.to_s+"\n"}
    self.class.class_variables.filter {|x| not saved_class_variables.include?(x) }.map {|x| self.class.remove_class_variable(x); _log x.to_s+"\n"}
    self.class.instance_variables.filter {|x| not saved_instance_methods.include?(x) }.map {|x| self.class.remove_instance_variables(x); _log x.to_s+"\n"}

def main()
    
    # const
    #_log A.class.to_s+"\n" # error
    #_log B.class.to_s+"\n" # error
    #_log CONST.to_s+"\n" # error
    foo
end
