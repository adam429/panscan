__TASK_NAME__ = "panbot_runner"

load(Task.load("panbot_runner"))

class SimulationRunner < PanRunner
    attr_accessor :block, :block_end, :epoch, :logs

    def initialize()
        @logs = []
        super
    end 

    def log(str)
        @logs.push str
    end

    def getEpoch
    end

    def run
    end

    def time_at_epoch(begin_epoch,end_epoch)
    end

    def time_at_block(begin_block,end_block)
    end

    def lastBlockOrder
    end

    def isLastBetable
    end

    def getCurrentEpoch
    end

    def getCurrentBlock
    end

    def getCurrentPayout
    end

    def getCurrentAmount
    end

    def betBull(sender,amount)
    end

    def betBear(sender,amount)
    end

    def endRound()
    end
end

def main
end