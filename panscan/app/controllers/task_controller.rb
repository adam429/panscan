class TaskController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create_workers
        StartWorkerJob.perform_later params[:num].to_i
        redirect_to "/task/worker"
    end

    def delete_instance
        worker = Worker.new
        worker.delete_instances([params[:id]])

        redirect_to "/task/worker"
    end

    def start_worker
        w = Worker.new
        w.start_worker(params[:id])

        redirect_to "/task/worker"
    end

    def restart_worker
        w = Worker.new
        w.restart_worker([params[:id]])

        redirect_to "/task/worker"
    end

    def delete_worker
        w = Worker.new
        w.delete_worker(params[:id])

        redirect_to "/task/worker"
    end





    def worker
        worker = Worker.new
        @workers = worker.get_workers

        @task = {}
        Task.where(status:"run").order(:run_timestamp).each do |t|
            @task[t.runner]= [t.name,(Time.now-t.run_timestamp)]
        end
    end

    def task_change_status
        task = Task.find(params[:id])
        task.status = params[:status]
        task.save
        if params[:status] == "kill" then
            begin
                w = Worker.new
                w.restart_worker([Task.find(params[:id]).runner])    
            rescue
            end
        end
        redirect_to "/task/#{params[:id]}"
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

                # tid -> name -> tid (url show name)
                redirect_to "/task/#{URI.escape(@task.name,"/")}" if Task.where(name:@task.name).where("tid is not null").order(save_timestamp: :desc).first.tid == tid
              else
                @task = Task.where(name:tid).where("tid is not null").order(save_timestamp: :desc).first
              end
            @new_task = false
        end

        # last trial for find task
        @task =  Task.find(tid) if @task==nil

        @runner = @task.runner
        @return = @task.html
        @output = @task.output
        @params = @task.params
    end

    def task_filter
        
        @task = Task.where(status:params[:status])
        if params[:class]=="name_task" then
            @task = @task.where("tid is not null")
        end
        if params[:class]=="closure_task" then
            @task = @task.where("tid is null")
        end
    end

    def task_all
        @prefix = params[:prefix] || ""
        @prefix.gsub!(/^\//,"")

        @name_task = Task.where("tid is not null").group(:status).count
        @closure_task = Task.where("tid is null").group(:status).count
        
        @running_task = Task.order(updated_at: :desc).where(status:"run").where("tid is not null").select(:schedule_at,:id,:tid,:name,:runner,:status,:params,:save_timestamp,:run_timestamp,:created_at,:updated_at)
        @schedule_task = Task.order(updated_at: :desc).where(status:"open").where("tid is not null").select(:schedule_at,:id,:tid,:name,:runner,:status,:params,:save_timestamp,:run_timestamp,:created_at,:updated_at)

        @task = Task.where("name like ?","#{@prefix}%").order(status: :asc,updated_at: :desc).where("tid is not null").select(:schedule_at,:id,:tid,:name,:runner,:status,:params,:save_timestamp,:run_timestamp,:created_at,:updated_at).all

        @path = []
        @task = @task.filter {|t|
            split = t.name.split("/")[@prefix.split("/").size,t.name.split("/").size]
            prefix = split[0]
            postfix = split[1] 
        
            puts "#{@prefix} - #{prefix} - #{postfix}"
            @path.push (prefix) if postfix!=nil
            postfix==nil
        }

        @path = @path.uniq.sort


    end

    def task_kill
        w = Worker.new
        w.restart_worker([Task.find_by_id(params[:tid]).runner])

        task = Task.find_by_id(params[:tid])
        task.status = "kill"
        task.save

        redirect_to '/task/all' 
    end

    def task_schedule_now
        task = Task.find_by_id(params[:tid])
        task.schedule_at = Time.now
        task.save
        
        redirect_to '/task/all' 
    end



    def task_run
        if params[:tid]=="(new)" then
            task = Task.new
            task.name = task.tid = SecureRandom.hex(8)
            task.code = params[:code]
            task.status = "open"
            task.params = json_params(params)
            task.save_timestamp = Time.now
            task.update_name
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
            task.update_name
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
        task.update_name
        task.save_timestamp = Time.now
        task.save
        render :json => {:action=> "open", :to => "/task/#{task.tid}"}
    end

    def task_save

        if params[:tid]=="(new)" then
            task = Task.new
            task.tid = SecureRandom.hex(8)
            task.code = params[:code]
            task.status = "edit"
            task.params = json_params(params)
            task.update_name
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

    def task_return_view
        task = nil
        if params[:tid] =~ /^[0-9a-f]{16}$/ then
            task = Task.find_by_tid(params[:tid])

            # tid -> name -> tid (url show name)
            Task.where(name:task.name).where("tid is not null").order(save_timestamp: :desc).first.tid == params[:tid]
            redirect_to "/task/view/#{URI.escape(task.name,"/")}" if Task.where(name:task.name).where("tid is not null").order(save_timestamp: :desc).first.tid == params[:tid]
            return
        else
            task = Task.where(name:params[:tid]).where("tid is not null").order(save_timestamp: :desc).first
        end

        render :inline => task.html
    end

    def task_json
        task = Task.find(params[:id])
        if task then
            json = task.attributes
            ret = ""
            begin
                ret = JSON.parse(task.return)["html"]
            rescue
                ret = task.return
            end
            json["return"] = ret

            render :json => json
        else
            render :json => {}
        end
    end
end
