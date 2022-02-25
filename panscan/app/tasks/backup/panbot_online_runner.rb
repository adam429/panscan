__TASK_NAME__ = "panbot_online_runner"


load(Task.load("panbot_runner"))


load(Task.load("database"))
load(Task.load("panbot_payout_bot"))


class OnlineRunner < PanRunner
    attr_accessor :block, :block_end, :epoch, :logs

    def initialize()
        @logs = []
        super
    end 

    def log(str)
        @logs.push str
    end

    def run
        $_log "run"
    end


    def getEpoch
    end


    def time_at_epoch(begin_epoch,end_epoch)
    end

    def time_at_block(begin_block,end_block)
    end

    def lastBlockOrder
    end

    def isLastBetable 
        "code"
    end

    def getCurrentEpoch
        "code"
    end

    def getCurrentBlock
        "code"
    end

    def getCurrentPayout
        "code"
    end

    def getCurrentAmount
        "code"
    end

    def betBull(sender,amount)
        "code"
    end

    def betBear(sender,amount)
        "code"
    end
end

def main
    bot_class = PayoutBot
    $log = _log
    
    _log ("db_init\n")
    database_init()
    _log ("db_init_done\n")

    min_amount = __min_amount__
    min_payout = __min_payout__
    bet_amount_factor = __bet_amount_factor__
    bet_amount_value = __bet_amount_value__
    
    config = {:min_amount => min_amount, :min_payout=>min_payout, :bet_amount_factor=>bet_amount_factor, :bet_amount_value=>bet_amount_value}

    runner = OnlineRunner.new()
    bot = bot_class.new(runner,config)
    _log ("run\n")
    runner.run
end