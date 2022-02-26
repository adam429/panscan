__TASK_NAME__ = "demo_clean_space"

    # $__saved_constants = self.class.constants
    # $__saved_methods = self.class.methods
    # $__saved_class_variables = self.class.class_variables
    # $__saved_instance_variables = self.instance_variables
    # $__saved_instance_methods = self.class.instance_methods
    # $__saved_global_variables = self.global_variables

    CONST=1
    
    class A
    end
    
    module B
    end

    def foo
        'foo'
    end
    
    @var1 = '1'
    @@var2 = '2'
    $var = '3'
    
    
    eval("""
    class #{self.class}
      def a
        'a'
      end
      def self.b
        'b'
      end
    end
    """)
    
    
    # _log("==clean up environment==\n")
    # _log("- constants\n")
    # self.class.constants.filter {|x| not $__saved_constants.include?(x) }.map {|x| _log x.to_s+"\n"; self.class.send(:remove_const, x); }
    # _log("- methods\n")
    # self.class.methods.filter {|x| not $__saved_methods.include?(x) }.map {|x| _log x.to_s+"\n"; eval("class <<#{self.class}\n remove_method :#{x}\n end") }
    # _log("- class_variables\n")
    # self.class.class_variables.filter {|x| not $__saved_class_variables.include?(x) }.map {|x| _log x.to_s+"\n"; self.class.remove_class_variable(x); }
    # _log("- instance_variables\n")
    # self.instance_variables.filter {|x| not $__saved_instance_variables.include?(x) }.map {|x| _log x.to_s+"\n"; remove_instance_variable(x); }
    # _log("- instance_methods\n")
    # self.class.instance_methods.filter {|x| not $__saved_instance_methods.include?(x) }.map {|x| _log x.to_s+"\n"; eval("undef #{x}"); }
    # _log("- global_variables\n")
    # self.global_variables.filter {|x| not $__saved_global_variables.include?(x) }.map {|x| _log x.to_s+"\n"; eval("#{x}=nil"); }

def main()
    
    _log A.class.to_s+"\n" # error
    _log B.class.to_s+"\n" # error
    _log CONST.to_s+"\n" # error
    _log foo #error
    _log @var1.to_s # nil
    _log @@var2.to_s # nil
    _log $var
    _log a
    _log self.class.b
    
end
