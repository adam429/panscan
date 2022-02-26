__TASK_NAME__ = "pancake_prediction"

require 'ethereum.rb'
require 'eth'

load(Task.load("database"))

class PancakePrediction
    attr_accessor :client, :contract, :bot_address, :address, :decoder, :encoder,:function_abi,:event_abi
    
    def initialize(gas_premium = 1)
        @gas_premium = gas_premium
        @bot_private_key = Vault.get("bot_private_key")
        @address = Vault.get("pancake_prediction_v2")

        @decoder = Ethereum::Decoder.new
        @encoder = Ethereum::Encoder.new
        
        abi = Vault.get("pancake_prediction_v2.abi")
    
        abi_constructor_inputs, abi_functions, abi_events = Ethereum::Abi.parse_abi(JSON.parse(abi))
        
        @function_abi = abi_functions.map do |x|
           ["0x"+x.signature,x]
        end.to_h
        
        @event_abi = abi_events.map do |x|
           ["0x"+x.signature,x]
        end.to_h


        @client = Ethereum::HttpClient.new(Vault.get("bsc_endpoint"))
        @contract = Ethereum::Contract.create(
            client: @client, 
            name: "pancake_prediction_v2", 
            address: @address,
            abi: abi
        )
        

        ## config chain_id for EIP-155
        Eth.configure { |c| c.chain_id = @client.net_version["result"].to_i }

        # update gas prices with gas_premium
        gas_price = @client.eth_gas_price["result"].to_i(16)
        @client.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i
        @contract.gas_price = ((gas_price / 1e9 * @gas_premium).round()*1e9).to_i

        # create key from private_key
        @bot_key = Eth::Key.new priv: @bot_private_key
        @bot_address = @bot_key.address
        @contract.key = @bot_key
        
    end
end

def main()
    database_init
     
    pan_action = PancakePrediction.new()
    _log pan_action.contract.call.current_epoch.to_s + "\n"



end
