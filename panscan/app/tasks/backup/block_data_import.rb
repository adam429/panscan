__TASK_NAME__ = "block_data_import"


require 'parallel'
require 'resolv-replace'

load(Task.load("database"))
load(Task.load("pancake_prediction"))
load(Task.load("auto-retry"))


def decode_params(decoder,log,name)
  if name=="Claim"
    return {
      "sender"=> "0x"+decoder.decode("address",log["topics"][1]),
      "epoch" => decoder.decode("uint256",log["topics"][2]),
      "amount" => decoder.decode("uint256",log["data"])/1e18
    }
  end
  if name=="BetBull"
    return {
      "sender"=> "0x"+decoder.decode("address",log["topics"][1]),
      "epoch" => decoder.decode("uint256",log["topics"][2]),
      "amount" => decoder.decode("uint256",log["data"])/1e18
    }
  end
  if name=="BetBear"
    return {
      "sender"=> "0x"+decoder.decode("address",log["topics"][1]),
      "epoch" => decoder.decode("uint256",log["topics"][2]),
      "amount" => decoder.decode("uint256",log["data"])/1e18
    }
  end
  if name=="LockRound"
    return {
      "epoch" => decoder.decode("uint256",log["topics"][1]),
      "round_id" => decoder.decode("uint256",log["topics"][2]),
      "price" => decoder.decode("int256",log["data"])/1e18
    }
  end
  if name=="EndRound"
    return {
      "epoch" => decoder.decode("uint256",log["topics"][1]),
    }
  end
  if name=="RewardsCalculated"
    data = decoder.decode_arguments(
          [
            Ethereum::FunctionInput.new({"type"=>"uint256","name"=>"rewardBaseCalAmount"}),
            Ethereum::FunctionInput.new({"type"=>"uint256","name"=>"rewardAmount"}),
            Ethereum::FunctionInput.new({"type"=>"uint256","name"=>"treasuryAmount"}),
          ], log["data"])
    return {
      "epoch" => decoder.decode("uint256",log["topics"][1]),
      "rewardBaseCalAmount" => data[0],
      "rewardAmount" => data[1],
      "treasuryAmount" => data[2],
    }
  end
  if name=="StartRound"
    return {"epoch" => decoder.decode("uint256",log["topics"][1]) }
  end
  return {}
end

def data_import_block(block_number,client,contract_addr,function_abi,event_abi,decoder)
     return "alredy exist" if Block.find_by_block_number(block_number)

    ## get block
    block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { client.eth_get_block_by_number(block_number,true)["result"] }
    block["block_number"] = block["number"].to_i(16)
    block["block_time"] = Time.at(block["timestamp"].to_i(16))
  
    ## get tx receipt
    transactions = block["transactions"].filter {|x| x["from"]==contract_addr.downcase or x["to"]==contract_addr.downcase }.map {|tx|  tx["block_number"]=block["block_number"]; tx["block_time"]=block["block_time"]; tx}

    transactions = Parallel.map(transactions,in_threads: 5) do |tx|
      tx["receipt"] = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { client.eth_get_transaction_receipt(tx["hash"])["result"] }
      tx
    end
  
    ## process tx
    transactions.map! do |tx|
      size = tx["input"].size
      if tx["input"]=='0x' then
        method_hash = tx["input"]
        input_data =  tx["input"]
        tx["method_name"]= ""
        tx["input_data"] = ""
      else
        method_hash = tx["input"][0,10]
        input_data = "0x"+tx["input"][10,size]  
        if function_abi[method_hash] then
          tx["method_name"]= function_abi[method_hash].name
          tx["input_data"] = decoder.decode_arguments(function_abi[method_hash].inputs,input_data)
        else
          tx["method_name"]= ""
          tx["input_data"] = ""
        end
      end
      tx["amount"] = tx["value"].to_i(16)/1e18
      tx["block_number"] = tx["blockNumber"].to_i(16)
      tx["gas_price"] = tx["gasPrice"].to_i(16)/1e9
      tx["gas"] = tx["gas"].to_i(16)
      tx["nonce"] = tx["nonce"].to_i(16)

      tx["cumulative_gas_used"] = tx["receipt"]["cumulativeGasUsed"].to_i(16)
      tx["gas_used"] = tx["receipt"]["gasUsed"].to_i(16)

      tx["status"] = tx["receipt"]["status"]=="0x1" ? true : false

      tx["event"]=tx["receipt"]["logs"].map do |log|
        event = {}
        event["log"] = log
        event["abi"] = event_abi[log["topics"][0]]
        event["name"] = event["abi"].name
        event["params"] = decode_params(decoder,log,event["name"])
        event
      end

      tx
    end
  
    ## save to active_record
    ar = Block.new()
    ar.difficulty = block["difficulty"].to_i(16)
    ar.total_difficulty = block["totalDifficulty"].to_i(16)
    ar.block_number = block["block_number"]
    ar.gas_limit = block["gasLimit"].to_i(16)
    ar.gas_used = block["gasUsed"].to_i(16)
    ar.miner = block["miner"]
    ar.block_hash = block["hash"]
    ar.parent_hash = block["parentHash"]
    ar.block_time = Time.at(block["timestamp"].to_i(16))
    ar.block_size = block["size"].to_i(16)

    ar.save!

    transactions.map do |tx|
      ar = Tx.new()
      ar.block_hash = tx["blockHash"]
      ar.tx_hash = tx["hash"]
      ar.from = tx["from"]
      ar.to = tx["to"]
      ar.method_name = tx["method_name"]
      ar.input_data = JSON.dump(tx["input_data"])

      ar.tx_type = tx["type"].to_i(16)
      ar.tx_status = tx["status"]


      ar.block_time = tx["block_time"]
      ar.block_number = tx["blockNumber"].to_i(16)
      ar.gas = tx["gas"]
      ar.gas_price = tx["gasPrice"]
      ar.nonce = tx["nonce"]
      ar.tx_index = tx["transactionIndex"].to_i(16)
      ar.amount = tx["value"].to_i(16)
      ar.cumulative_gas_used = tx["cumulative_gas_used"]
      ar.gas_used = tx["gas_used"]
      ar.contract_address = tx["receipt"]["contractAddress"]

      begin
        ar.save!
      rescue ActiveRecord::RecordNotUnique 
      end
    end

    transactions.map {|x| x["event"]}.flatten.map do |event|
      ar = Event.new()
      ar.name = event["name"]
      ar.params = JSON.dump(event["params"])
      ar.event_abi = event["abi"].event_string
      ar.input_type = event["abi"].input_types
      ar.input_name = event["abi"].inputs
      ar.log_index = event["log"]["logIndex"].to_i(16)
      ar.tx_index = event["log"]["transactionIndex"].to_i(16)
      ar.block_hash = event["log"]["blockHash"]
      ar.tx_hash = event["log"]["transactionHash"]
      ar.block_number = event["log"]["blockNumber"].to_i(16)
      ar.event_key = "#{ar.block_number}-#{ar.tx_index}-#{ar.log_index}"

      begin
        ar.save!
      rescue ActiveRecord::RecordNotUnique 
      end
    end

end


def main()
    database_init(false) # allow to write
    
    Object.include AutoRetry
    block_numbers = __block_begin__..__block_end__
    
    pan_call = PancakePrediction.new
    
    Parallel.map(block_numbers.to_a,in_threads: 10) do |block_number|  
      _log  "#{Time.now} blocks: #{block_number}\n" if block_number%10000==0
      data_import_block(block_number,pan_call.client,pan_call.address,pan_call.function_abi,pan_call.event_abi,pan_call.decoder)
    end
    
end
