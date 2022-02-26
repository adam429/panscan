__TASK_NAME__ = "panbot_online_runner"

require 'ethereum.rb'
require 'eth'

load(Task.load("panbot_runner"))


load(Task.load("database"))
load(Task.load("window_array"))
load(Task.load("auto-retry"))

load(Task.load("panbot_payout_bot"))
load(Task.load("pancake_prediction"))

class OnlineRunner < PanRunner
    include AutoRetry
    def initialize()
        @logs = []
        @rpc_record = WindowArray.new(60)
        @logger = lambda do |str| self.log(str) end
        @gas_premium = 2
        
        @pan_action = PancakePrediction.new(@gas_premium)
        @client = @pan_action.client
        @contract = @pan_action.contract
        @bot_address = @pan_action.bot_address
        # @client = Ethereum::HttpClient.new(Vault.get("bsc_endpoint"))
        # @contract = Ethereum::Contract.create(
        #     client: @client, 
        #     name: "pancake_prediction_v2", 
        #     address: Vault.get("pancake_prediction_v2"), 
        #     abi: Vault.get("pancake_prediction_v2.abi")
        # )

        # ## config chain_id for EIP-155
        # Eth.configure { |c| c.chain_id = @client.net_version["result"].to_i }

        # # update gas prices with gas_premium
        # gas_price = @client.eth_gas_price["result"].to_i(16)
        # @client.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i
        # @contract.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i

        # # create key from private_key
        # @bot_key = Eth::Key.new priv: @bot_private_key
        # @bot_address = @bot_key.address
        # @contract.key = @bot_key
        
        log "=== Bot Address: #{@bot_address} - #{get_balance(@bot_address)} BNB ==="
        
        _get_current_epoch
        super
    end 

    def log(str)
        Thread.new {
            str = str +"\n"
            # @logs.push(str)
            $output.call (str)
            Log.log(str)    
        }
    end
        
    def bot_action
        # only run once bot decision 
        if @epoch[:lock_countdown] < __trigger_second__ then
            log "=== Bot Logic start at #{Time.now.to_fs(:db)} ==="
            @bot.each do |b|
                b.mainLoop
            end
            log "=== Bot Logic end at #{Time.now.to_fs(:db)} ==="
            sleep(10)
        end
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
                bot_action() if @epoch[:lock_countdown] < 10 
            end    
            print_short_stats()
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

    def getEpoch
    end

    def time_at_epoch(begin_epoch,end_epoch)
    end

    def time_at_block(begin_block,end_block)
    end

    def lastBlockOrder
    end

    def isLastBetable 
        6<@epoch[:lock_countdown] and @epoch[:lock_countdown]<9
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
        # start a new epoch
        _get_current_epoch()

        @tick = 0
    end


    def bnb_decimal(amount)
        return (amount * 1e18).to_i
    end

    def _get_last_block()
        time = Time.now()
        last_block = auto_retry(@logger) { @client.eth_get_block_by_number('latest', false) } # get latest block details 
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


    def _get_round()
        time = Time.now()
        current_round = auto_retry(@logger) { @contract.call.rounds(@current_epoch) }
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


end

def main
    bot_class = PayoutBot
    $output = lambda do |str| _log(str) end
    
    database_init()

    min_amount = __min_amount__
    min_payout = __min_payout__
    bet_amount_factor = __bet_amount_factor__
    bet_amount_value = __bet_amount_value__
    
    config = {:min_amount => min_amount, :min_payout=>min_payout, :bet_amount_factor=>bet_amount_factor, :bet_amount_value=>bet_amount_value}

    runner = OnlineRunner.new()
    bot = bot_class.new(runner,config)
    runner.run   
end