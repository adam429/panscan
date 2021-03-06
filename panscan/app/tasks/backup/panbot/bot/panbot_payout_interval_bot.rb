__TASK_NAME__ = "panbot/bot/panbot_payout_interval_bot"

load(Task.load("panbot/bot/panbot_panbot"))

class PayoutIntervalBot < PanBot
    attr_accessor :config
    
    def mainLoop
        if isLastBetable then
            log "#{getCurrentEpoch} #{getCurrentBlock} #{isLastBetable} #{getCurrentPayout} #{getCurrentAmount}"
            payout_bull, payout_bear = getCurrentPayout
            amount = getCurrentAmount

            payout = [payout_bull, payout_bear].max 
            if payout > @config[:min_payout] and payout < @config[:max_payout] and amount >  @config[:min_amount] and amount < @config[:max_amount] then
                log "make bet"
                betBull(self,getCurrentAmount * @config[:bet_amount_factor] + @config[:bet_amount_value]) if payout_bull > payout_bear
                betBear(self,getCurrentAmount * @config[:bet_amount_factor] + @config[:bet_amount_value]) if payout_bull < payout_bear
            else
                log "do not bet"
            end
        end
    end

    def initialize(runner, config={})
        @config = config

        super(runner)
    end 
end

def main
end