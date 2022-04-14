__TASK_NAME__ = "panbot/online/panbot_online_runner_bot4"

require 'ethereum.rb'
require 'eth'

load(Task.load("panbot/panbot_runner"))

load(Task.load("base/database"))
load(Task.load("base/window_array"))
load(Task.load("base/auto-retry"))

load(Task.load("panbot/bot/panbot_payout_interval_bot"))
load(Task.load("panbot/online/pancake_prediction"))

class OnlineRunner < PanRunner
    include AutoRetry
    def initialize()
        @bot_id = __bot_id__
        @logs = []
        @rpc_record = WindowArray.new(60)
        @logger = lambda do |str| self.log(str) end
        @gas_premium = 2
        
        @bot_private_key = Vault.get("bot_private_key")[@bot_id]
        
        @pan_action = PancakePrediction.new(@gas_premium,@bot_private_key,Vault.get("bsc_endpoint"))
        @client = @pan_action.client
        @contract = @pan_action.contract
        
        @pan_action_backup = PancakePrediction.new(@gas_premium,@bot_private_key,Vault.get("bsc_endpoint_backup"))
        @client_backup = @pan_action_backup.client
        @contract_backup = @pan_action_backup.contract
                
        
        @bot_address = @pan_action.bot_address
        
        
        @log_buffer = []

        log "=== Bot Address: #{@bot_address} - #{get_balance(@bot_address)} BNB ==="
        
        _get_current_epoch
        super
    end 

    def run
        new_epoch
        _get_round()
        print_short_stats()

        dynamic_interval( -> {
            @interval=30
            @interval=10 if @epoch[:lock_countdown] < 50 
            @interval=1 if @epoch[:lock_countdown] < 20
            @interval=0.01 if @epoch[:lock_countdown] < 10    
            @interval=40 if @epoch[:lock_countdown] < 5
        }) do
            @tick = @tick+1
            _get_round()

            if @epoch[:lock_countdown] < 0 then
                # next epoch begin
                new_epoch
            else

                loop do
                    if Time.now - @last_block_time >= 4 then
                        # retry backup
                        log "=== Block Latency switch to backup ==="
                        _get_round(:backup)
                        if Time.now - @last_block_time >= 4 then
                            log "=== Block Latency Error: last  [#{@last_block_number} - #{@last_block_time.to_fs(:db)}] at #{Time.now.to_fs(:db)} diff #{Time.now-@last_block_time} ==="
                            # latency err, break
                            break
                        end
                    end
                    
                    # no latency, run bot_action
                    bot_action() if @epoch[:lock_countdown] < 10 
                    break
                end
                
            end    
            print_short_stats()
        end
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
        true
        # 6<@epoch[:lock_countdown] and @epoch[:lock_countdown]<9
    end

    def getCurrentEpoch
        @current_epoch
    end

    def getCurrentBlock
    end

    def getCurrentPayout
        return @epoch[:bullPayout],@epoch[:bearPayout]
    end

    def getCurrentAmount
        return @epoch[:totalAmount]
    end

    def betNone(sender)
        log "=== Bot give up bet at #{Time.now.to_fs(:db)}==="
    end

    def betBull(sender,amount)
        log "=== Bot betBull #{amount} at #{Time.now.to_fs(:db)}==="

        function_name = "betBull"
        function_args = [@current_epoch]
        sign_transcat(function_name, function_args, bnb_decimal(amount))    
    end

    def betBear(sender,amount)
        log "=== Bot betBear #{amount} at #{Time.now.to_fs(:db)}==="

        function_name = "betBear"
        function_args = [@current_epoch]
        sign_transcat(function_name, function_args, bnb_decimal(amount))    
    end

    private
    def print_short_stats()
        stats = ""
        stats = stats + "epoch #{@current_epoch} | "
        stats = stats + "tick #{@tick} | "
        stats = stats + "now #{ Time.now.to_fs(:db) } | "
        stats = stats + "lockAt #{ @epoch[:lockTimestamp].to_fs(:db) } | "
        stats = stats + "countdown #{@epoch[:lock_countdown]} | "
        stats = stats + "pool #{@epoch[:totalAmount].round(2)} | "
        stats = stats + "bull #{@epoch[:bullPayout].round(2)} | "
        stats = stats + "bear #{@epoch[:bearPayout].round(2)} | "
        stats = stats + "rpc #{@rpc_record.avg.round(4)} | "
        stats = stats + "interval #{@interval} "

        log(stats)
    end

    def new_epoch()
        flush_log()

        # start a new epoch
        _get_current_epoch()

        @tick = 0
    end


    def bnb_decimal(amount)
        return (amount * 1e18).to_i
    end

    def _get_last_block(endpoint = :main)
        time = Time.now()
        last_block = auto_retry(@logger) { @client.eth_get_block_by_number('latest', false) } if endpoint==:main
        last_block = auto_retry(@logger) { @client_backup.eth_get_block_by_number('latest', false) } if endpoint==:backup
        time = Time.now()-time
        @rpc_record.push(time)
        @last_block_time = Time.at(last_block["result"]["timestamp"].to_i(16))
        @last_block_number = last_block["result"]["number"].to_i(16)
    end

    def _get_current_epoch()
        time = Time.now()
        @current_epoch = auto_retry(@logger) { @contract.call.current_epoch }
        time = Time.now()-time
        @rpc_record.push(time)

        return @current_epoch
    end


    def _get_round(endpoint = :main)
        _get_last_block(endpoint)         
        
        time = Time.now()
        current_round = auto_retry(@logger) { @contract.call.rounds(@current_epoch) } if endpoint == :main
        current_round = auto_retry(@logger) { @contract_backup.call.rounds(@current_epoch) } if endpoint == :backup
        time = Time.now()-time
        @rpc_record.push(time)
        
        startTimestamp = Time.at(current_round[1])
        lockTimestamp = Time.at(current_round[2])
        closeTimestamp = Time.at(current_round[3])
        lock_countdown = (lockTimestamp-Time.now()).round(3)
        lockPrice = current_round[4]/1e8.to_f
        closePrice = current_round[5]/1e8.to_f
        totalAmount = current_round[8]/1e18.to_f
        bullAmount = current_round[9]/1e18.to_f
        bearAmount = current_round[10]/1e18.to_f
        rewardBaseCalAmount = current_round[11]/1e18.to_f
        rewardAmount = current_round[12]/1e18.to_f
        bullPayout = totalAmount/bullAmount
        bearPayout = totalAmount/bearAmount    

        @epoch = {startTimestamp:startTimestamp,lockTimestamp:lockTimestamp,closeTimestamp:closeTimestamp,lock_countdown:lock_countdown,
                  lockPrice:lockPrice,closePrice:closePrice,totalAmount:totalAmount,bullAmount:bullAmount,
                  bearAmount:bearAmount,rewardBaseCalAmount:rewardBaseCalAmount,
                  rewardAmount:rewardAmount,bullPayout:bullPayout,bearPayout:bearPayout}
    end        

    # sign trans
    def sign_transcat(function_name, function_args, value=0)
        # client - Ethereum.rb client
        # contract - Ethereum.rb contract
        # function_name (string) - name of solidity payable method we want to call (camel case)
        # function_args (array) - arguments desired to use in method
        # key - Eth::Key used to sign transaction

        key = @contract.key

        function = @contract.parent.functions.find { |f| f.name == function_name }
        abi = @contract.abi.find { |abi| abi['name'] == function_name }

        encoder = Ethereum::Encoder.new
        inputs = abi['inputs'].map { |input| OpenStruct.new(input) }
        input = encoder.encode_arguments(inputs, function_args)
        data = encoder.ensure_prefix(function.signature + input)

        tx_args = {
            from: key.address,
            to: @contract.address,
            data: data,
            value: value,
            nonce: auto_retry(@logger) { @client.get_nonce(key.address) },
            gas_limit: @client.gas_limit,
            gas_price: @client.gas_price
        }
        tx = Eth::Tx.new(tx_args)
        tx.sign(key)

        time = Time.now()
        tx = auto_retry(@logger) { @client.eth_send_raw_transaction(tx.hex)["result"] }
        time = Time.now()-time        
        @rpc_record.push(time)
        return tx
    end

    def get_balance(address)
        time = Time.now()
        ret = auto_retry(@logger) { @client.eth_get_balance(address)["result"].to_i(16) / 1e18.to_f }
        time = Time.now()-time

        @rpc_record.push(time)
        return ret
    end

    def log(str)
        str = "bot-#{@bot_id}:#{Time.now.to_i}.#{ ((Time.now.to_f % 1).round(3).to_s+"000")[2,3] }|#{str}"
        @log_buffer.push (str)
        $logger.call (str)
        
        flush_log() if @interval==nil or @interval>=10
    end
        
    def flush_log()
        while str=@log_buffer.shift do
            Log.log(str)
        end
    end
    
    def window_shift_adj(trigger_second)
        lock_time = @epoch[:lockTimestamp] 
        last_block_time = @last_block_time
        
        diff = 0 if (lock_time.to_i - last_block_time.to_i) % 3 == 0 
        diff = -1 if (lock_time.to_i - last_block_time.to_i) % 3 == 2
        diff = -2 if (lock_time.to_i - last_block_time.to_i) % 3 == 1
    
            
        if diff!=0 and @saved_diff!=diff then
            log "===Align Window Shift #{diff} - lock_time #{lock_time.to_fs(:db)} - last_block_time #{last_block_time.to_fs(:db)} / #{@last_block_number} ==="
        end
        @saved_diff = diff
        
        return trigger_second+diff
    end
        
    def bot_action
        # only run once bot decision 
        trigger_second = window_shift_adj(__trigger_second__)
        if trigger_second-0.5 < @epoch[:lock_countdown] and @epoch[:lock_countdown] < trigger_second then
            log "=== Bot Logic start at #{Time.now.to_fs(:db)} ==="
            @bot.each do |b|
                b.mainLoop
            end
            log "=== Bot Logic end at #{Time.now.to_fs(:db)} ==="

            sleep(10)
        end
    end
    
    def dynamic_interval(dynamic_interval_adj)
        clock = Time.now()
        dynamic_interval_adj.call
        while true do
            if Time.now()-clock > @interval  then
                clock = Time.now()  
                
                yield

                dynamic_interval_adj.call
            end
        end
    end

end

def main
    bot_class = PayoutIntervalBot
    database_init()

    min_amount = __min_amount__
    max_amount = __max_amount__
    min_payout = __min_payout__
    max_payout = __max_payout__
    bet_amount_factor = __bet_amount_factor__
    bet_amount_value = __bet_amount_value__
    
    config = {:min_amount => min_amount, :min_payout=>min_payout, :max_amount => max_amount, :max_payout=>max_payout, :bet_amount_factor=>bet_amount_factor, :bet_amount_value=>bet_amount_value}

    runner = OnlineRunner.new()
    bot = bot_class.new(runner,config)
    runner.run   
end