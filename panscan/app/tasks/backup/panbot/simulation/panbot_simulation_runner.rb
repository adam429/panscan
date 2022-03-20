__TASK_NAME__ = "panbot/simulation/panbot_simulation_runner"

load(Task.load("panbot/panbot_runner"))

class SimulationRunner < PanRunner
    attr_accessor :block, :block_end, :epoch, :logs

    def initialize(logger=nil)
        @logs = []
        @logger = logger
        super
    end 

    def log(str)
        @logs.push str
    end

    def getEpoch
        begin
            if @epoch==nil or @block > @epoch.lock_block_number then
                @epoch = Block.find_by_block_number(@block).ar_epoch
            end
            if @epoch==nil then
                begin
                    @new_block = Epoch.find_by_epoch(Block.find_by_block_number(@block-1).ar_epoch.epoch+1).start_block_number            
                rescue
                    @new_block = nil
                end
                
                if @new_block == nil or @new_block < @block then
                    return nil
                end

                @epoch = Block.find_by_block_number(@block).ar_epoch
            end
            return @epoch
        rescue
            @logger.call "#{@epoch} - #{@block}\n"
            return nil
        end
    end

    def run
        while @block<=@block_end do
            @bot.each do |b|
                b.mainLoop
            end
            @block = @block + 1

            ar_epoch = nil
    
            # skip logic        
            loop do
                ar_epoch = getEpoch
                break if ar_epoch
                @block = @block + 1
            end
            
            endRound() if ar_epoch.lock_block_number == @block
        end
    end

    def time_at_epoch(begin_epoch,end_epoch)
        @block = Epoch.find_by_epoch(begin_epoch).start_block_number
        @block_end = Epoch.find_by_epoch(end_epoch).lock_block_number
    end

    def time_at_block(begin_block,end_block)
        @block = begin_block
        @block_end = end_block
    end

    def lastBlockOrder
        ar_epoch = getEpoch
        return ar_epoch.lock_block_number - block
    end

    def isLastBetable
        lastBlockOrder == 3
    end

    def getCurrentEpoch
        getEpoch.epoch
    end

    def getCurrentBlock
        @block
    end

    def getCurrentPayout
        ar_epoch = getEpoch
        return ar_epoch.get_bull_payout(@block),ar_epoch.get_bear_payout(@block),ar_epoch.get_bull_amount(@block),ar_epoch.get_bear_amount(@block)
    end

    def getCurrentAmount
        ar_epoch = getEpoch
        return ar_epoch.get_amount(@block)
    end

    def betBull(sender,amount)
        log "===betBull #{amount}==="
        sender.epoch_bet = ["bull",amount,lastBlockOrder-2]+getCurrentPayout() if sender.epoch_bet==nil
    end

    def betBear(sender,amount)
        log "===betBear #{amount}==="
        sender.epoch_bet = ["bear",amount,lastBlockOrder-2]+getCurrentPayout() if sender.epoch_bet==nil
    end

    def endRound()
        ar_epoch = getEpoch

        @logger.call "#{Time.now} - #{ar_epoch.epoch}\n" if ar_epoch.epoch % 100 == 0

        @block = ar_epoch.lock_block_number
        log "===endRound #{ar_epoch.epoch}==="

        log "===origin #{ar_epoch.bet_result} #{getCurrentPayout} ==="
        _, _, amount_bull, amount_bear = getCurrentPayout
        
        @bot.each do |b|
            next if b.epoch_bet==nil
            if b.epoch_bet[0]=="bull" then
                amount_bull = amount_bull + b.epoch_bet[1]
            end
            if b.epoch_bet[0]=="bear" then
                amount_bear = amount_bear + b.epoch_bet[1]
            end
        end

        total_amount = amount_bull+amount_bear
        log "===new #{ar_epoch.bet_result} #{[total_amount/amount_bull, total_amount/amount_bear, amount_bull,amount_bear]}==="


        @bot.each do |b|
            if b.epoch_bet then
                round = {:epoch=>ar_epoch.epoch, :bet=>b.epoch_bet[0],:amount=>b.epoch_bet[1],:bet_block_order=>b.epoch_bet[2],
                        :bull_payout=>total_amount/amount_bull, :bear_payout=>total_amount/amount_bear, 
                        :bull_amount=>amount_bull, :bear_amount=>amount_bear, :bet_result=>ar_epoch.bet_result,
                        :ob_bull_payout=>b.epoch_bet[3],:ob_bear_payout=>b.epoch_bet[4],:ob_amount=>b.epoch_bet[5]+b.epoch_bet[6]
                        }
                b.bet_result.push round
                b.epoch_bet = nil
            else
                round = {:epoch=>ar_epoch.epoch, :bet=>"",:amount=>nil,:bet_block_order=>nil,
                        :bull_payout=>total_amount/amount_bull, :bear_payout=>total_amount/amount_bear, 
                        :bull_amount=>amount_bull, :bear_amount=>amount_bear, :bet_result=>ar_epoch.bet_result
                        }
                b.bet_result.push round
            end
        end
    end

end