class TaskController < ApplicationController
    def worker
        @pingpong = Task.where("name like ?","ping task%").where(status:["run","close"]).where("created_at >= ?",Time.now()-300).select(:runner).distinct(:runner).order(:runner).map {|x| x.runner}
        @running = Task.where(status:"run").select(:runner).distinct(:runner).order(:runner).map {|x| x.runner}
    end
end
