class Task < ActiveRecord::Base
    def self.create_task(name,code)
      task = Task.new
      task.status = "open"
      task.code = code
      task.name = name
      task.save
    end
    
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

    def update_name()    
      ast = Parser::CurrentRuby.parse(self.code)
      match = ast.children.filter {|x| x.type==:lvasgn and x.children.first==:__TASK_NAME__ }
      task_name = eval(Unparser.unparse(match.last.children.last))
      self.name = task_name
    end
    
    def log(str)
      self.output = self.output + str
      self.save
    end
    
    class Runner
      def initialize(task)
        @_task = task
      end
      def _log(str)
        @_task.log(str)
      end
      def _run(code)
        eval(code + "\n main()",binding)
      end
    end
    
    def param_code
      code = self.code
      params = JSON.parse(self.params)
      params.each {|k,v| code.gsub!(/__#{k}__/,v) }
      return code
    end

    def run
      runner = Runner.new(self)
      self.log("#{Time.now} == begin run ==\n")
      begin
        ret = runner._run(param_code(self.code))
      rescue => error
        self.log "Exception Class: #{ error.class.name }\n"
        self.log "Exception Message: #{ error.message }\n"
        self.log "Exception Backtrace:\n#{ error.backtrace.join("\n") }\n"
        self.log("#{Time.now} == abort run ==\n")
        self.status = "abort"
        self.save
      else
        self.return = ret
        self.log("#{Time.now} == end run ==\n")
        self.status = "close"
        self.save      
      end
    end

    def self.run_loop(runner)
        loop do
            task = Task.take_task(runner) 
            task.run if task
            sleep(1)
        end
    end
  end