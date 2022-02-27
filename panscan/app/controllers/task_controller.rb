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

                # tid -> name -> tid (url show name)
                redirect_to "/task/#{@task.name}" if Task.where(name:@task.name).where("tid is not null").order(save_timestamp: :desc).first.tid == tid
              else
                @task = Task.where(name:tid).where("tid is not null").order(save_timestamp: :desc).first
              end
            @new_task = false
        end
        @runner = @task.runner
        @return = @task.html
        @output = @task.output
        @params = @task.params
    end

    def task_all
        @running_task = Task.order(updated_at: :desc).where(status:"run").where("tid is not null").select(:id,:tid,:name,:runner,:status,:params,:save_timestamp,:run_timestamp,:created_at,:updated_at)

        @task = Task.order(updated_at: :desc).where("tid is not null").select(:id,:tid,:name,:runner,:status,:params,:save_timestamp,:run_timestamp,:created_at,:updated_at)
    end

    def task_kill
        task = Task.find_by_tid(params[:tid])
        task.status="kill"
        task.save

        instance, _ = task.runner.split("_")
        docker = task.runner

        # todo: need a class to put together
        # todo: need dockerfile to let remote docker have pem file in the right path
        worker = "panworker-0_2ad2"
        instance, _ = worker.split("_")
        docker = worker

        get_public_ip_str = "aws lightsail get-instances --no-cli-pager --region 'us-east-1' --query 'instances[].{name:name,publicIpAddress:publicIpAddress}'"
        data = `#{get_public_ip_str}`
        public_ips = JSON.parse(data).map {|x| [x["name"],x["publicIpAddress"]]}.to_h
        ip = public_ips[instance]
        cmd = "docker restart #{docker}"          
        `ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem -o 'StrictHostKeyChecking no' ubuntu@#{ip} '#{cmd}'`
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
            redirect_to "/task/view/#{task.name}"
            return
        else
            task = Task.where(name:params[:tid]).where("tid is not null").order(save_timestamp: :desc).first
        end

        render :inline => task.html
    end

    def task_json
        task = Task.find_by_tid(params[:tid])
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
