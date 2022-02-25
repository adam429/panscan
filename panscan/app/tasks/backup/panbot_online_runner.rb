__TASK_NAME__ = "panbot_online_runner"

require 'ethereum.rb'
require 'eth'

load(Task.load("panbot_runner"))


load(Task.load("database"))
load(Task.load("panbot_payout_bot"))


class OnlineRunner < PanRunner
    attr_accessor :block, :block_end, :epoch, :logs

    def initialize()
        @logs = []

        @gas_premium = 2

        @client = Ethereum::HttpClient.new(Vault.get("bsc_endpoint"))

        @contract = Ethereum::Contract.create(
            client: @client, 
            name: "pancake_prediction_v2", 
            address: Vault.get("pancake_prediction_v2"), 
            abi: Vault.get("pancake_prediction_v2.abi")
        )

        ## config chain_id for EIP-155
        Eth.configure { |c| c.chain_id = @client.net_version["result"].to_i }

        # update gas prices with gas_premium
        gas_price = @client.eth_gas_price["result"].to_i(16)
        @client.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i
        @contract.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i

        # create key from private_key
        @bot_key = Eth::Key.new priv: @bot_prviate_key
        @bot_address = @bot_key.address
        @contract.key = @bot_key

        super
    end 

    def log(str)
        @logs.push str
    end
    
    def output(str)
        $output.call (str)
    end

    def run
        time = Time.now()
        ret = @contract.call.current_epoch
        time = Time.now()-time

        time = Time.now()
        ret = @contract.call.current_epoch
        time = Time.now()-time

        output ret.to_s+"\n"
        output time.to_s+"\n"
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
    
    Log.log("log from bot")
end