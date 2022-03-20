__TASK_NAME__ = "panbot/bot/panbot_panbot"

class PanBot
    attr_accessor :runner
    attr_accessor :epoch_bet
    attr_accessor :bet_result

    def initialize(runner)
        @runner = runner
        @runner.bot.push(self)
        @bet_result = []
    end 

    def mainLoop
    end

    def method_missing(m, *args)
        return @runner.send(m) if args==[]
        return @runner.send(m,*args) if args!=[]
    end

end

def main
end