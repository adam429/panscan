__TASK_NAME__ = "panbot_payout_interval_bot"

load(Task.load("panbot_panbot"))

class PayoutIntervalBot < PanBot
    attr_accessor :config
    
    def mainLoop
        if isLastBetable then
            log "#{getCurrentEpoch} #{getCurrentBlock} #{isLastBetable} #{getCurrentPayout} #{getCurrentAmount}"
            payout_bull, payout_bear = getCurrentPayout
            amount = getCurrentAmount

            if [payout_bull, payout_bear].max > @config[:min_payout] and  [payout_bull, payout_bear].max <= @config[:min_payout] + 0.1 and
                amount >  @config[:min_amount] and amount <= @config[:min_amount] + 1 then
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