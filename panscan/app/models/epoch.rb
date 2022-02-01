class Epoch < ApplicationRecord
    has_many :detail,  primary_key: "epoch", foreign_key: "epoch", class_name:"EpochDetail"

    def self.first_epoch
        Epoch.order(:epoch).first.epoch    
    end
    def self.last_epoch
        Epoch.order(:epoch).last.epoch    
    end

    def block
        Block.where("? <= block_time and block_time <= ?",start_timestamp,lock_timestamp+10).order("block_number")
    end

    def event
        Event.where(tx_hash:tx.map {|x| x.tx_hash}).order("block_number")
    end

    def tx
        Tx.where(block_number:block.map {|x| x.block_number})
    end

    def bet_result
        return "bear" if lock_price > close_price
        return "bull" if lock_price < close_price
        return "draw" if lock_price == close_price
    end

    def get_last_block_order(block_number)
        return nil if lock_block_number==0
        return lock_block_number - block_number 
    end

    # def get_detail_all()
    #     @cache_block_number = self.detail.map {|x| [x.block_number,x]}.to_h
    # end

    def get_detail(block_number)
        @cache_block_number = self.detail.map {|x| [x.block_number,x]}.to_h if @cache_block_number==nil
        return @cache_block_number[block_number]
        # if @cache_block_number[block_number] then
        #     return @cache_block_number[block_number]
        # else
        #     @cache_block_number[block_number]=self.detail.where("block_number=?",block_number).first
        #     return @cache_block_number[block_number]
        # end



    end

    def get_count(block_number)
        detail = get_detail(block_number)
        return detail.bet_count if detail
    end

    def get_bull_payout(block_number)
        detail = get_detail(block_number)
        return detail.bull_payout if detail
        return 0.0
    end

    def get_bear_payout(block_number)
        detail = get_detail(block_number)
        return detail.bear_payout if detail
        return 0.0
    end

    def get_bull_amount(block_number)
        detail = get_detail(block_number)
        return detail.bull_amount if detail
    end

    def get_bear_amount(block_number)
        detail = get_detail(block_number)
        return detail.bear_amount if detail
    end

    def get_amount(block_number)
        detail = get_detail(block_number)
        return detail.bull_amount+detail.bear_amount if detail
    end

    def get_wrong_bet(method_name,block_number)
        detail = get_detail(block_number)
        return false if detail==nil

        if method_name=="betBull" then
            return true if detail.bull_payout < detail.bear_payout
        end
        if method_name=="betBear" then
            return true if detail.bull_payout > detail.bear_payout
        end
        return false
    end

    # todo


    def gen_map()
        if @tx_map==nil or @block_map==nil  then
            @tx_map = {}
            self.event.each {|event|
                amount = JSON.parse(event.params)["amount"]
                @tx_map[event.tx_hash] = [
                    event.name,
                    amount,
                    event.block_number
                ]
            }            
            bull_amount = 0
            bear_amount = 0
            count =0

            @block_map = {}
            self.block.each {|block|
                tx = @tx_map.to_a.map {|x| x.flatten}.filter {|x| x[3]==block.block_number}
                tx = tx.filter do |x| x[1]=="BetBull" or x[1]=="BetBear" end
                tx.each do |x|
                if x[1]=="BetBull" then
                    bull_amount=bull_amount+x[2]
                end
                if x[1]=="BetBear" then
                    bear_amount=bear_amount+x[2]
                end
                end
                count = count +tx.size
                @block_map[block.block_number] = [
                    bull_amount==0?0:(bull_amount+bear_amount)/bull_amount,
                    bear_amount==0?0:(bull_amount+bear_amount)/bear_amount, 
                    bull_amount,
                    bear_amount,
                    count
                ]
            }            

        end
    end

    def get_bet_amount(tx)
        gen_map()
        @tx_map[tx.tx_hash][1] if tx.tx_status and (tx.method_name=="betBear" or tx.method_name=="betBull")
    end

    def get_address_bet(address)
        if @address_map==nil then
            epoch_last = lock_block_number
            # epoch_first = Epoch.find_by_epoch(self.epoch-288).get_first_block.block_number
            epoch_first = Epoch.where("epoch >= ?",self.epoch-288).order(:epoch).first.start_block_number
            @address_map = Tx.where("?<= block_number and block_number <= ? and (method_name = ? or method_name = ?)",epoch_first,epoch_last,"betBear","betBull").group(:from).count
        end
        @address_map[address] or 0
    end


    def self.get_epoch(block_number)
        block_time = Block.find_by_block_number(block_number).block_time
        Epoch.where("start_timestamp<=? and ?<=lock_timestamp",block_time,block_time-10).first
    end


    

end
