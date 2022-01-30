class Epoch < ApplicationRecord
    # def block
    #     Block.where("? <= block_time and block_time <= ?",start_timestamp,lock_timestamp+10).order("block_number")
    # end

    # def tx
    #     tx = Tx.where(block_number:block.map {|x| x.block_number})
    #     event = event
    #     return tx
    # end

    # def event
    #     tx = Tx.where(block_number:block.map {|x| x.block_number})
    #     Event.where(tx_hash:tx.map {|x| x.tx_hash}).order("block_number")
    # end

    def bet_result
        return "bear" if lock_price > close_price
        return "bull" if lock_price < close_price
        return "draw" if lock_price == close_price
    end

    # def get_count(block_number)
    #     gen_map()
    #     (@block_map[block_number][4])
    # end

    # def total_count()
    #     event.where("name = ? or name = ?","BetBear","BetBull").count
    # end

    # def get_last_block
    #     if @last_block==nil then
    #         @last_block = block.where("? < block_time and block_time < ?",lock_timestamp-1.5,lock_timestamp+1.5).first
    #     end
    #     @last_block
    # end

    # def get_first_block
    #     if @first_block==nil then
    #         @first_block = block.where("? < block_time and block_time < ?",start_timestamp-1.5,start_timestamp+1.5).first
    #     end
    #     @first_block
    # end

    # def gen_map()
    #     if @tx_map==nil or @block_map==nil  then
    #         @tx_map = {}
    #         self.event.each {|event|
    #             amount = JSON.parse(event.params)["amount"]
    #             @tx_map[event.tx_hash] = [
    #                 event.name,
    #                 amount,
    #                 event.block_number
    #             ]
    #         }            
    #         bull_amount = 0
    #         bear_amount = 0
    #         count =0

    #         @block_map = {}
    #         self.block.each {|block|
    #             tx = @tx_map.to_a.map {|x| x.flatten}.filter {|x| x[3]==block.block_number}
    #             tx = tx.filter do |x| x[1]=="BetBull" or x[1]=="BetBear" end
    #             tx.each do |x|
    #             if x[1]=="BetBull" then
    #                 bull_amount=bull_amount+x[2]
    #             end
    #             if x[1]=="BetBear" then
    #                 bear_amount=bear_amount+x[2]
    #             end
    #             end
    #             count = count +tx.size
    #             @block_map[block.block_number] = [
    #                 bull_amount==0?0:(bull_amount+bear_amount)/bull_amount,
    #                 bear_amount==0?0:(bull_amount+bear_amount)/bear_amount, 
    #                 bull_amount,
    #                 bear_amount,
    #                 count
    #             ]
    #         }            

    #     end
    # end

    # def get_last_block_order(block_number)
    #     return nil if get_last_block==nil
    #     return get_last_block.block_number - block_number 
    # end

    # def get_bet_amount(tx)
    #     gen_map()
    #     @tx_map[tx.tx_hash][1] if tx.tx_status and (tx.method_name=="betBear" or tx.method_name=="betBull")
    # end

    # def get_address_bet(address)
    #     if @address_map==nil then
    #         epoch_last = self.get_last_block.block_number
    #         # epoch_first = Epoch.find_by_epoch(self.epoch-288).get_first_block.block_number
    #         epoch_first = Epoch.where("epoch >= ?",self.epoch-288).order(:epoch).first.get_first_block.block_number
    #         @address_map = Tx.where("?<= block_number and block_number <= ? and (method_name = ? or method_name = ?)",epoch_first,epoch_last,"betBear","betBull").group(:from).count
    #     end
    #     @address_map[address] or 0
    # end

    # # def get_payout(block_number)
    # #     gen_map()
    # #     @block_map[block_number]
    # # end

    # def get_bull_payout(block_number)
    #     gen_map()
    #     (@block_map[block_number] or [0,0])[0]
    # end
    # def get_bear_payout(block_number)
    #     gen_map()
    #     (@block_map[block_number] or [0,0])[1]
    # end

    # def get_bull_amount(block_number)
    #     gen_map()
    #     @block_map[block_number][2]
    # end

    # def get_bear_amount(block_number)
    #     gen_map()
    #     @block_map[block_number][3]
    # end

    # def get_amount(block_number)
    #     gen_map()
    #     (@block_map[block_number][2])+(@block_map[block_number][3])
    # end

    # def get_wrong_bet(method_name,block_number)
    #     if method_name=="betBull" then
    #         return true if get_bull_payout(block_number-1)<get_bear_payout(block_number-1)
    #     end
    #     if method_name=="betBear" then
    #         return true if get_bull_payout(block_number-1)>get_bear_payout(block_number-1)
    #     end
    #     return false
    # end

    # def self.get_epoch(block_number)
    #     block_time = Block.find_by_block_number(block_number).block_time
    #     Epoch.where("start_timestamp<=? and ?<=lock_timestamp",block_time,block_time-10).first
    # end
end
