
          def self.__task
            if @__task then 
              return @__task 
            end
            @__task=Task.find(15539)
          end 
        __TASK_NAME__ = "foo"


def main()
    n = 2
    
    1/0

    foo
end

          def __main()
            @raw_ret = main()
            html = @raw_ret.to_s
            if defined?(render_html)=="method" then
                html=ERB.new(render_html()).result(binding)
            end
            
            return {raw_ret:@raw_ret,html:html}
          end
          
          __main()
        