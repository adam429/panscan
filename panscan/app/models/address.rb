class Address < ApplicationRecord
    def delete
      raise ActiveRecord::ReadOnlyRecord
    end


    class << self
      attr_accessor :client,:get_abi,:decoder,:panbot_address
    end
    
    def self.update_tag(address,tag)
      return if address==nil
      
      addr = Address.find_by_addr(address)
      return if addr==nil

      if tag=="" then
        addr.tag = nil
      else  
        addr.tag = tag
      end

      addr.save
    end
    
    def self.load(address)
      return if address==nil
      
      addr = Address.find_by_addr(address)
      return addr if addr
      
      addr = Address.new
      addr.addr = address
      
      is_panbot= self.panbot_address[address]
      addr.is_panbot = is_panbot
      addr.is_contract = self.is_contract(address)
      addr.contract_abi = self.get_abi.call(address) if addr.is_contract 
            
      begin
        addr.save!
      rescue ActiveRecord::RecordNotUnique 
      end
    end
    
    def self.is_contract(address)
      addr = Address.find_by_addr(address)
      return addr.is_contract if addr
      return self.client.eth_get_code(address,"latest")["result"]!="0x"
    end
    
    def decode_params(input)
      if @function_abi==nil and @event_abi==nil then    
        abi_constructor_inputs, abi_functions, abi_events = Ethereum::Abi.parse_abi(abi)
  
        @function_abi = abi_functions.map do |x|
           ["0x"+x.signature,x]
        end.to_h
  
        @event_abi = abi_events.map do |x|
           ["0x"+x.signature,x]
        end.to_h
      end
            
      if input=='0x' then
        return "Transfer",""
      else
        method_hash = input[0,10]
        # input_data = "0x"+input[10,input.size]  
        if @function_abi!=nil and @function_abi[method_hash] then
          method_hash = @function_abi[method_hash].name
        end
        return method_hash,""
        # method_params = ""
          # begin
          #   method_params = self.class.decoder.decode_arguments(@function_abi[method_hash].inputs,input_data)
          # rescue
          #   method_params = ""
          # end
          # return method_hash,method_params
      end
    end 
    
    def abi
      return @abi if @abi
      if contract_abi == "Contract source code not verified" then
         @abi=[]
         return @abi
      end
      @abi = JSON.parse(contract_abi)
    end
    
    def short_addr
      addr[0,6]+".."+addr[-4,4]
    end

    def calculate_percentile(json, percentile)
      array = JSON.parse(json)
      array.sort[(percentile * array.length).ceil - 1] or 0
    end

    def stats
      """=== stats ===
bet epoch: #{bet_epoch_cnt} / all_epoch: #{Epoch.count} = bet_ratio: #{(bet_epoch_cnt*100.to_f / Epoch.count).round(2)}%

invest_cnt: #{invest_cnt} / bet_cnt: #{bet_cnt} = bet_success_rate: #{ (invest_cnt*100.to_f / bet_cnt).round(2)  }%

bet_bull_cnt: #{bet_bull_cnt} / bet_cnt: #{bet_cnt} = bet_bull_ratio: #{( bet_bull_cnt*100.to_f / bet_cnt).round(2)}%

avg_bet_amt: #{avg_bet_amt.round(4)}
bet_amt_percentile 25%: #{calculate_percentile(bet_amt,0.25).round(4)} | 50%: #{calculate_percentile(bet_amt,0.5).round(4)}| 75%: #{calculate_percentile(bet_amt,0.75).round(4)}

avg_last_block_order: #{avg_last_block_order.round(2)}
right_bet_ratio: #{(right_bet_ratio*100).round(2)}%
win_bet_ratio: #{(win_bet_ratio*100).round(2)}%

invest_cnt: #{invest_cnt} invest_amt: #{invest_amt.round(4)} return_amt: #{return_amt.round(4)}
total_roi: #{ (return_amt*100 / invest_amt).round(2)}% """
    end
end