class EpochController < ApplicationController
    def foo
    end

    def epoch
        @epoch = Epoch.find_by_epoch(params[:id])
    end

    def address
    end
end
