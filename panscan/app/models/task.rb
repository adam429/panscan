require 'parser/current'
require 'unparser'

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

    def self.run_loop(runner)
      loop do
          task = Task.take_task(runner) 
          task.run if task
          sleep(1)
      end
    end

    def self.load(address,binding)
      addr, code = address.split("/")
      code="*" if code==nil
      code=code.to_sym

      task = nil
      if addr =~ /^[0-9a-f]{16}$/ then
        task = Task.find_by_tid(addr)
      else
        task = Task.where(name:addr).order(save_timestamp: :desc).first
      end

      ast = Parser::CurrentRuby.parse(task.code)
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
      binding.eval(select_code)

      return select_code
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
    
    def log(str)
      self.output = self.output + str
      self.save
    end

    
    def param_code
      code = self.code.clone
      params = self.params == nil ? [] : JSON.parse(self.params)
      params.each {|k,v| code.gsub!(/__#{k}__/,v) }
      return code
    end

    def run
      # reset runner class binding everytime
      Task.send(:remove_const, :Runner) if Task.constants.include?(:Runner)
      code = <<~CODE
class Runner
  def initialize(task)
    @_task = task
  end
  def _log(str)
    @_task.log(str)
  end
  def _run(param_code)
    eval(param_code + "\n main()",binding)
  end
end
CODE
      eval(code)

      runner = Runner.new(self)
      self.log("#{Time.now} == begin run ==\n")
      begin
        ret = runner._run(param_code)
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

  end