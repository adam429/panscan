require 'parser/current'
require 'unparser'
require 'erb'
require 'opal'

class Task < ActiveRecord::Base
    def self.create_task(name,code,schedule_at = Time.at(0))
      task = Task.new
      task.status = "open"
      task.code = code
      task.name = name
      task.schedule_at = schedule_at
      task.save
      return task.id
    end
    
    ## for worker
    def self.take_task(runner)
      task = nil
      Task.transaction do
        task = Task.lock.where(status:"open").order(:updated_at).where("schedule_at is null or schedule_at <= ?",Time.now).first
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
      addr, code = address.split("::")
      code=[] if code==nil
      if code[0]=="(" and code[-1]==")" then
        code = code[1..-2]
        code = code.split(",")
      else
        code = [code]
      end
    
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
      match = match.filter do |x| 
          m = false
          code.each do |c|
            m = true if (x.children and x.children.first==c)
            m = true if (x.children and x.children.first.class==Parser::AST::Node and x.children.first.type==:const and x.children.first.children[1]==c )
          end
          m
      end
      select_code = match.map do |m|
        Unparser.unparse(m)
      end.join("\n")

      filename = "#{addr}_#{code.join('_')}.rb"
      dirname = File.dirname(filename)
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end

      File.write filename, select_code
      return filename
    end

    def self.run_remote(address,params={},schedule_at=Time.at(0))
      params = params.map {|k,v| [k,v.to_s]}.to_h
      task = nil
      if address =~ /^[0-9a-f]{16}$/ then
        task = Task.find_by_tid(address)
      else
        task = Task.where(name:address).where("tid is not null").order(save_timestamp: :desc).first
      end

      raise "Task.load() cannot find script #{addr}" if task==nil

      new_task = Task.new(task.attributes)  
      new_task.id = nil    
      new_task.tid = nil
      new_task.params = JSON.dump(params)
      new_task.status = "open"
      new_task.schedule_at = schedule_at
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

    def abi
      abi = code.scan(/(__[a-zA-Z0-9_]+__)/).flatten
      abi = abi.filter {|x| x!='__TASK_NAME__'}.map {|x| x.gsub(/^__/,"").gsub(/__$/,"") }
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
      def _task
        @_task
      end
      def _run(param_code)
        eval_code = '''
$logger =  lambda {|x| _log(x.to_s+"\n")}        
$task = _task
def __main()
  @raw_ret = main()
  html = @raw_ret.to_s

  if defined?(render_html)=="method" then
      html=ERB.new(render_html()).result(binding)
  end

  if defined?(render_js_rb)=="method" then
    js_rb=ERB.new(render_js_rb()).result(binding)

    builder = Opal::Builder.new.build_str(js_rb,"")                
    html=html + "<script>(function() {  #{builder.to_s}  })();</script>"
  end


  if defined?(schedule_at)=="method" then
    next_schedule_at = schedule_at()
  end

  return {raw_ret:@raw_ret,html:html,schedule_at:next_schedule_at}
end

__main()
        '''
        load_code =  param_code
        Dir.mkdir("tmp") unless File.exists?("tmp")
        File.write "tmp/runner_task_closure_#{@_task.id}.rb",load_code
        load "tmp/runner_task_closure_#{@_task.id}.rb"

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

        if ret[:schedule_at] then
          self.status = "open"
          self.schedule_at = ret[:schedule_at]
        else
          self.status = "close"
        end
        self.save      
      end
    end

  end