__TASK_NAME__ = "panbot/panbot_runner"

class PanRunner
    attr_accessor :bot

    def getCurrentEpoch
    end

    def getCurrentPayout
    end

    def getCurrentAmount
    end

    def getCurrentBlock
    end

    def isLastBetable
    end

    def betBull(sender,amount)
    end

    def betBear(sender,amount)
    end
    
    def betNone(sender)
    end

    def endRound()
    end

    def log(str)
    end

    def run
    end

    def initialize(logger=nil)
        @bot=[]
    end 
end

def main
end