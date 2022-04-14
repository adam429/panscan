__TASK_NAME__= "data_import/transfer_data_import"

require 'parallel'
require 'resolv-replace'

load(Task.load("base/database"))
load(Task.load("panbot/online/pancake_prediction"))
load(Task.load("base/auto-retry"))

def data_import_transfer(block_number,client,addr_hash)
  ## check for skip
  return "alredy exist" if Transfer.where(block_number:block_number).count>0
  
    
  ## get block
  block = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { client.eth_get_block_by_number(block_number,true)["result"] }
  block["block_number"] = block["number"].to_i(16)
  block["block_time"] = Time.at(block["timestamp"].to_i(16))

  ## get tx receipt
  transactions = block["transactions"].filter {|x| addr_hash[x["from"]] or addr_hash[x["to"]] }.map {|tx|  tx["block_number"]=block["block_number"]; tx["block_time"]=block["block_time"]; tx}

  transactions.map {|x| Address.load(x["from"]); nil }
  transactions.map {|x| Address.load(x["to"]); nil }

  transactions = Parallel.map(transactions,in_threads: 10) do |tx|
    tx["receipt"] = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { client.eth_get_transaction_receipt(tx["hash"])["result"] } 
    tx
  end

  ## process tx
  transactions.map! do |tx|
    size = tx["input"].size

    if tx["to"]!=nil then
      to = Address.find_by_addr(tx["to"])
      if to.is_contract then
        tx["method_name"],tx["method_params"] = to.decode_params(tx["input"])
      else
        tx["method_name"],tx["method_params"] = "Transfer",""
      end
    else
      tx["method_name"],tx["method_params"] = "CreateContract",""
      tx["to"] = tx["receipt"]["contractAddress"]
    end

    tx["amount"] = tx["value"].to_i(16)/1e18
    tx["block_number"] = tx["blockNumber"].to_i(16)
    tx["gas_price"] = tx["gasPrice"].to_i(16)/1e9
    tx["gas"] = tx["gas"].to_i(16)
    tx["nonce"] = tx["nonce"].to_i(16)

    tx["status"] = tx["receipt"]["status"]=="0x1" ? true : false

    tx    
  end
        
  transactions.filter {|x| x["status"]==true}.map do |tx|
    ar = Transfer.new()  
    ar.from = tx["from"]
    ar.to = tx["to"]
    ar.amount = tx["value"].to_i(16)
    ar.method_name = tx["method_name"]
      
    begin
      ar.method_params = JSON.dump(tx["method_params"])
    rescue
    end
    ar.tx_hash = tx["hash"]
    ar.block_time = tx["block_time"]
    ar.block_number = tx["blockNumber"].to_i(16)
      
    begin
      ar.save!
    rescue ActiveRecord::RecordNotUnique 
    end
  end
  
end


def main()
    database_init(false) # allow to write

    Object.include AutoRetry
    pan_call = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { PancakePrediction.new }
    
    get_abi = -> (contract_addr) {
      api_url = "https://api.bscscan.com/api?module=contract&action=getabi&address=#{contract_addr}&apikey=#{Vault.get("bscscan-apikey")}"
      abi = auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { 
          ret = JSON.parse(response = Faraday.get(api_url).body)["result"] 
          if ret == "Max rate limit reached" then
              sleep 1
              raise JSON::ParserError
          end
          ret
      }
      return abi
    }
    
    Address.client = pan_call.client
    Address.get_abi = get_abi
    Address.decoder = Ethereum::Decoder.new
    
    
    _log "generate addr_hash start\n"
    time = Time.now()
    
    all_address = Tx.select(:from).distinct.all.map {|x| x.from}
    addr_hash = all_address.map {|x| [x,true]}.to_h
    Address.panbot_address = addr_hash
    
    _log "generate addr_hash end - time #{Time.now-time} s\n"

    block_numbers = __block_begin__..__block_end__
    
    Parallel.map(block_numbers.to_a,in_threads: 10) do |block_number|  
      _log  "#{Time.now} blocks: #{block_number}\n" if block_number%100==0
      data_import_transfer(block_number,pan_call.client,addr_hash)
    end
    nil
end
