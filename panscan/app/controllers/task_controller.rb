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
            @task.code = '''
def main()
    _log ("hello world\n")
    return "value"
end
'''
            @new_task = true
        else 
            @task = Task.find_by_tid(tid)
            @new_task = false
        end
    end

    def task
    end

    def task_save
        puts param[:tid]
        # puts params.to_s
        # render json: [1,2,3]
    end
end
