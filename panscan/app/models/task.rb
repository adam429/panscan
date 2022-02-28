require 'parser/current'
require 'unparser'
require 'erb'

class Task < ActiveRecord::Base
    def self.create_task(name,code)
      task = Task.new
      task.status = "open"
      task.code = code
      task.name = name
      task.save
      return task.id
    end
    
    ## for worker
    def self.take_task(runner)
      task = nil
      Task.transaction do
        task = Task.lock.where(status:"open").first
        if task then
          task.status = "run"
          task.runner = runner
          task.output = "#{Time.now} runner #{runner} take task #{task.id} : #{task.name}\n"
          task.run_timestamp = Time.now
          task.save      
        end
      end
      return task
    end

    def self.run_loop(runner="local_runner")
      loop do
          task = Task.take_task(runner) 
          if task then
            task.run 
            break # end process, docker will reset new            
          end
          sleep(1)
      end
    end

    ## for task editor
    def self.load(address)
      addr, code = address.split("/")
      code="*" if code==nil
      code=code.to_sym

      task = nil
      if addr =~ /^[0-9a-f]{16}$/ then
        task = Task.find_by_tid(addr)
      else
        task = Task.where(name:addr).where("tid is not null").order(save_timestamp: :desc).first
      end

      raise "Task.load() cannot find script #{addr}" if task==nil

      begin
        ast = Parser::CurrentRuby.parse(task.code)
      rescue =>e
        raise "Task.load() find error in script #{addr}. Parser error: #{e.message}"
      end
      match = ast.children.filter {|x| not (x.type==:lvasgn and x.children.first==:__TASK_NAME__) and not (x.type==:def and x.children.first==:main) }
      if code!=:* then
        match = match.filter {|x| 
          (x.children and x.children.first==code) or
          (x.children and x.children.first.class==Parser::AST::Node and x.children.first.type==:const and x.children.first.children[1]==code )
        }
      end
      select_code = match.map do |m|
        Unparser.unparse(m)
      end.join("\n")

      File.write "#{addr}.rb", select_code
      return "#{addr}.rb"
    end

    def self.run_remote(address,params={})
      params = params.map {|k,v| [k,v.to_s]}.to_h
      task = nil
      if address =~ /^[0-9a-f]{16}$/ then
        task = Task.find_by_tid(address)
      else
        task = Task.where(name:address).where("tid is not null").order(save_timestamp: :desc).first
      end
      new_task = Task.new(task.attributes)  
      new_task.id = nil    
      new_task.tid = nil
      new_task.params = JSON.dump(params)
      new_task.status = "open"
      new_task.save
      return new_task
    end

    def self.is_pending(task)
      Task.find(task.id).status == "open"
    end
    def self.is_running(task)
      Task.find(task.id).status == "run"
    end
    def self.is_done(task)
      status = Task.find(task.id).status
      return (status == "close" or status == "abort")
    end
    def self.wait_until_running(task)
      loop do
        update_task = Task.find(task.id)
        return update_task if update_task.status=="run"
        sleep(1)
      end
    end
    def self.wait_until_done(task)
      if task.class==Array then
        loop do
          update_task = task.map do |t|
            Task.find(t.id)
          end
          return update_task if update_task.filter {|t| t.status == "close" or t.status == "abort" }.size==update_task.size
          sleep(1)          
        end        
      else
        loop do
          update_task = Task.find(task.id)
          return update_task if (update_task.status == "close" or update_task.status == "abort")
          sleep(1)
        end
      end
    end

    def raw_ret()
      begin
        JSON.parse(self.return, {allow_nan: true})["raw_ret"] if self.return
      rescue
      end
    end

    def html()
      begin
        JSON.parse(self.return, {allow_nan: true})["html"] if self.return
      rescue
      end
    end

    def update_name()    
      begin
        ast = Parser::CurrentRuby.parse(self.code)
        match = ast.children.filter {|x| x.type==:lvasgn and x.children.first==:__TASK_NAME__ }
        task_name = eval(Unparser.unparse(match.last.children.last))
        self.name = task_name
      rescue 
      end
    end
    
    def log(obj)
      self.output = self.output + obj.to_s
      self.output = self.output[-[1_000_000,self.output.size].min,[1_000_000,self.output.size].min]

      self.save
    end

    
    def param_code
      code = self.code.clone
      params = self.params == nil ? [] : JSON.parse(self.params)
      params.each {|k,v| code.gsub!(/__#{k}__/,v) }
      return code
    end

    class Runner
      def initialize(task)
        @_task = task
      end
      def _log(str)
        @_task.log(str)
      end
      def _run(param_code)

        # def _log(str)
        #   self.__task.log(str)
        # end
        
        before_code = """
def self.__task
  if @__task then 
    return @__task 
  end
  @__task=Task.find(#{@_task.id})
end 
        """


        after_code = '''
def __main()
  @raw_ret = main()
  html = @raw_ret.to_s
  if defined?(render_html)=="method" then
      html=ERB.new(render_html()).result(binding)
  end
  
  return {raw_ret:@raw_ret,html:html}
end
        '''
        load_code =  param_code
        File.write "runner_task_closure.rb",code
        load "runner_task_closure.rb"

        eval_code = before_code + "__main();" + after_code
        eval(eval_code,binding)
      end
    end   

    def run
      runner = Runner.new(self)
      self.log("#{Time.now} == begin run ==\n")
      begin
        ret = runner._run(param_code)
      rescue ScriptError, StandardError => error        
        if error.message == "panbot::task::cmd::shutdown" then
          # self.reload
          self.log "Exception Class: #{ error.class.name }\n"
          self.log "Exception Message: #{ error.message }\n"
          self.log "Exception Backtrace:\n#{ error.backtrace.join("\n") }\n"
          self.log("#{Time.now} == shutdown ==\n")
          self.status = "close"
          self.save  
          raise error
        end


        self.log("Exception Class: #{ error.class.name }\n")
        self.log("Exception Message: #{ error.message }\n")

        begin
          file,line =  error.backtrace[0].split(":")
          if file!="(irb)" and file!="(eval)"
              line = line.to_i
              src = File.readlines(file)
              self.log("Exception Source: #{file}:#{line}\n")
              self.log (src[[line-6,0].max,11].map.with_index {|x,i| (i==(line>5 ? 5 : line-1) ? "--> " : "    ") + x }.join()+"\n")
          end
        rescue
        end

        self.log("Exception Backtrace:\n#{ error.backtrace.join("\n") }\n")
        self.log("#{Time.now} == abort run ==\n")
        self.status = "abort"
        self.save
      else
        # self.reload
        self.return = JSON.dump(ret)
        self.log("#{Time.now} == end run ==\n")
        self.status = "close"
        self.save      
      end
    end

  end