__TASK_NAME__ = "demo_clean_space"

    saved_constants = self.class.constants
    saved_methods = self.class.methods
    saved_class_variables = self.class.class_variables
    saved_instance_variables = self.instance_variables

    saved_instance_methods = self.class.instance_methods
    saved_global_variables = self.global_variables

    CONST=1
    
    class A
    end
    
    module B
    end

    def foo
    end
    
    @var1 = 1
    @@var2 = 2
    $var = 3
    
    
    
    eval("""
    class #{self.class}
      def a
      end
    end
    """)
    

    _log("==constants==\n")
    self.class.constants.filter {|x| not saved_constants.include?(x) }.map {|x| _log x.to_s+"\n"; self.class.send(:remove_const, x); }
    _log("==methods==\n")
    self.class.methods.filter {|x| not saved_methods.include?(x) }.map {|x| _log x.to_s+"\n"; self.class.remove_method(x); }
    _log("==class_variables==\n")
    self.class.class_variables.filter {|x| not saved_class_variables.include?(x) }.map {|x| _log x.to_s+"\n"; self.class.remove_class_variable(x); }
    _log("==instance_variables==\n")
    self.instance_variables.filter {|x| not saved_instance_variables.include?(x) }.map {|x| _log x.to_s+"\n"; remove_instance_variable(x); }
    _log("==instance_methods==\n")
    self.class.instance_methods.filter {|x| not saved_instance_methods.include?(x) }.map {|x| _log x.to_s+"\n"; eval("undef #{x}"); }
    _log("==global_variables==\n")
    self.global_variables.filter {|x| not saved_global_variables.include?(x) }.map {|x| _log x.to_s+"\n"; eval("#{x}=nil"); }

def main()
    
    # const
    #_log A.class.to_s+"\n" # error
    #_log B.class.to_s+"\n" # error
    #_log CONST.to_s+"\n" # error
    #_log foo #error
    #_log @var1.to_s # nil
    
end
