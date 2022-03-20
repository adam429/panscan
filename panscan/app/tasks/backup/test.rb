__TASK_NAME__ = "test"


require 'parallel'
require 'resolv-replace'

load(Task.load("base/database"))
load(Task.load("base/auto-retry"))
load(Task.load("panbot/online/pancake_prediction"))


def calc_bot_stats(address)
  ar_addr = Address.find_by_addr(address)
  if ar_addr==nil then
    Address.load(address) 
    ar_addr = Address.find_by_addr(address)
  end
 
#   return if ar_addr.bet_cnt!=nil
  
  txes = Tx.where('"from" = ?',address).where("method_name=? or method_name=?",'betBull','betBear').order(:block_number)

  tx_map = {}
  Event.where(tx_hash:txes.map {|x| x.tx_hash}).each {|event|
      amount = JSON.parse(event.params)["amount"]
      tx_map[event.tx_hash] = [
         event.name,
         amount,
         event.block_number
     ]
  }        

  epoch_map = {}

  tx_block_map = txes.map {|x| [x.tx_hash,x.block_number]}.to_h
  block_epoch_map = Block.where(block_number:txes.map {|x| x.block_number}).map {|x| [x.block_number,x.epoch]}.to_h
  epoch_ar_map = Epoch.where(epoch:block_epoch_map.to_a.map{|x| x[1]}).map {|x| [x.epoch,x]}.to_h

  tx_block_map.each { |k,v| 
      epoch_map[k] = epoch_ar_map[block_epoch_map[v]]
  }

    avg_last_block_order = []
    wrong_bet_list =[]
    win_bet_list = []
    avg_amount = []
    invest_cnt = 0
    invest_amt = 0
    return_amt = 0

    Parallel.map(txes,in_threads: 10) do |tx|
      round_ret = 0
      x = tx_map[tx.tx_hash]
      avg_amount.push(x[1]) if x!=nil

      epoch = epoch_map[tx.tx_hash]
      next if epoch==nil

      last_block_order = epoch.get_last_block_order(tx.block_number)

      next if last_block_order==nil
      avg_last_block_order.push(last_block_order) if tx.tx_status 
      try_count = 3

begin
      wrong_bet = epoch.get_wrong_bet(tx.method_name,tx.block_number);
      try_count = try_count-1
rescue NoMethodError=>e
  sleep(1)
  retry if try_count>0
  puts tx.inspect
  raise NoMethodError
end

      wrong_bet_list.push wrong_bet
      win_bet = tx.method_name[-4,4].downcase == epoch.bet_result 
      win_bet_list.push win_bet

      if tx.tx_status then
        invest_cnt = invest_cnt +1
        bet_amt = (tx_map[tx.tx_hash] or [0,0,0])[1]
        invest_amt = invest_amt + bet_amt

        round_ret =  - bet_amt
        if tx.method_name=="betBear" and epoch.bet_result=="bear" then
          round_ret = round_ret + bet_amt * epoch.bear_payout * 0.97
        end
        if tx.method_name=="betBull" and epoch.bet_result=="bull" then
          round_ret = round_ret + bet_amt * epoch.bull_payout * 0.97
        end
        return_amt = return_amt + round_ret

      end
  end
  ar_addr.bet_epoch_cnt = txes.map {|x| x.block ? x.block.epoch : 0}.uniq.size
  ar_addr.invest_cnt = txes.where(tx_status:true).size
  ar_addr.bet_cnt = txes.size
  ar_addr.bet_bull_cnt = txes.where(method_name:"betBull").size
  ar_addr.bet_bear_cnt = txes.where(method_name:"betBear").size
  ar_addr.avg_bet_amt = avg_amount.sum / avg_amount.size.to_f
  ar_addr.bet_amt = JSON.dump(avg_amount)
  ar_addr.avg_last_block_order = avg_last_block_order.sum / avg_last_block_order.size.to_f
  ar_addr.right_bet_ratio = wrong_bet_list.filter{|x| x==false}.size / wrong_bet_list.size.to_f
  ar_addr.win_bet_ratio = win_bet_list.filter{|x| x==true}.size / win_bet_list.size.to_f
  ar_addr.invest_amt = invest_amt
  ar_addr.return_amt = return_amt
  ar_addr.save
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
    

    Address.panbot_address = Cache.get("bot_stats_calc.panbot_address")
    addr_list = Cache.get("bot_stats_calc.addr_list")
    
    addr_begin = __addr_begin__
    addr_end = __addr_end__
    
    _log "addr_begin #{addr_begin} - addr_end #{addr_end}\n"
    
    addr_list.filter {|x| addr_begin<=x[2] and x[2]<=addr_end}.map {|x| x[0]}.each do |addr|
        _log "#{addr}\n"
        calc_bot_stats(addr)
    end
end
