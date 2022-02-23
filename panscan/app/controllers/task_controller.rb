class TaskController < ApplicationController
    skip_before_action :verify_authenticity_token

    def worker
        @pingpong = Task.where("name like ?","ping task%").where(status:["run","close"]).where("created_at >= ?",Time.now()-300).select(:runner).distinct(:runner).order(:runner).map {|x| x.runner}
        @running = Task.where(status:"run").select(:runner).distinct(:runner).order(:runner).map {|x| x.runner}
    end

    def task_view    
        tid = params[:tid]
        if tid.downcase == 'new' then
            @task = Task.new
            i = "#"+"{i}"
            time = "#"+"{time}"
            @task.code = <<~'CODE'
__TASK_NAME__ = "hello-task"

def main()
    time = Time.now()

    10.times do |i|
        _log ("the #{i} run\n")
        sleep(1)
    end
    time = Time.now()-time

    return "takes <span style='color:red'>#{time}</span> seconds"
end
CODE
            @new_task = true
        else 
            if tid =~ /^[0-9a-f]{16}$/ then
                @task = Task.find_by_tid(tid)
              else
                @task = Task.where(name:tid).order(save_timestamp: :desc).first
              end
            @new_task = false
        end
        @runner = @task.runner
        begin
            @return = JSON.parse(@task.return)["html"]
        rescue
            @return = @task.return
        end
        @output = @task.output
        @params = @task.params
    end

    def task_all
        @task = Task.all.order(updated_at: :desc)
    end

    def wiki
    end


    def task_run
        if params[:tid]=="(new)" then
            task = Task.new
            task.name = task.tid = SecureRandom.hex(8)
            task.code = params[:code]
            task.status = "open"
            task.params = json_params(params)
            task.save_timestamp = Time.now
            task.save
            render :json => {:action=> "redirect", :to => "/task/#{task.tid}"}
        else
            task = Task.find_by_tid(params[:tid])
            task.code = params[:code]
            task.status = "open"
            task.runner = nil
            task.output = nil
            task.return = nil
            task.params = json_params(params)
            task.save_timestamp = Time.now
            task.save            
            render :json => {:action=> "message", :message => "task is pending to run"}
        end
    end

    def task_fork
        task = Task.new
        task.tid = SecureRandom.hex(8)
        task.code = params[:code]
        task.status = "edit"
        task.runner = nil
        task.output = nil
        task.return = nil
        task.params = json_params(params)
        task.save_timestamp = Time.now
        task.save
        render :json => {:action=> "redirect", :to => "/task/#{task.tid}"}
    end

    def task_save

        if params[:tid]=="(new)" then
            task = Task.new
            task.tid = SecureRandom.hex(8)
            task.code = params[:code]
            task.status = "edit"
            task.update_name
            task.params = json_params(params)
            task.save_timestamp = Time.now
            task.save
            render :json => {:action=> "redirect", :to => "/task/#{task.tid}"}
        else
            task = Task.find_by_tid(params[:tid])
            task.code = params[:code]
            cur_status = task.status
            task.status = "edit"
            task.runner = nil
            task.output = nil
            task.return = nil
            task.params = json_params(params)
            task.update_name
            task.save_timestamp = Time.now
            task.save  
            render :json => {:action=> "message", :message => "Save Success"} if cur_status == "edit" 
            render :json => {:action=> "redirect", :to => "/task/#{task.tid}"} if cur_status != "edit" 
        end
    end

    def json_params(params)
        params_hash = []
        if params[:params] then 
            params[:params].each do |k,v|
                params_hash << [k,v]
            end
        end
        params_hash=params_hash.to_h
        JSON.dump(params_hash)
    end

    def task_json
        task = Task.find_by_tid(params[:tid])
        if task then
            render :json => task.attributes
        else
            render :json => {}
        end
    end
end
