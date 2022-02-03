class Epoch < ApplicationRecord
    before_destroy :destroy_callback, prepend: true 
    def destroy_callback
      throws :abort 
    end
  
    has_many :detail,  primary_key: "epoch", foreign_key: "epoch", class_name:"EpochDetail"

    def self.first_epoch
        Epoch.order(:epoch).first.epoch    
    end
    def self.last_epoch
        Epoch.order(:epoch).last.epoch    
    end

    def block
        Block.where(" epoch = ? ",self.epoch).order("block_number")
    end
    def event
        Event.where(block_number:self.block.map {|x| x.block_number}).order("block_number")
    end
    def tx
        Tx.where(block_number:self.block.map {|x| x.block_number}).order("block_number")
    end

    def _block
        next_epoch = Epoch.find_by_epoch(self.epoch+1)
        next_epoch_starttime = next_epoch.start_timestamp if next_epoch!=nil
        next_epoch_starttime = lock_timestamp+9           if next_epoch==nil
      
        if next_epoch_starttime==start_timestamp then
          next_epoch = Epoch.find_by_epoch(self.epoch+2)
          next_epoch_starttime = next_epoch.start_timestamp if next_epoch!=nil
          next_epoch_starttime = lock_timestamp+9           if next_epoch==nil
        end
      
        Block.where("? <= block_time and block_time < ?",start_timestamp,next_epoch_starttime).order("block_number").limit(108)
    end

    # def _event
    #     Event.where(block_number:_block.map {|x| x.block_number}).order("block_number")
    # end

    # def _tx
    #     Tx.where(block_number:_block.map {|x| x.block_number}).order("block_number")
    # end

    def bet_result
        return "bear" if lock_price > close_price
        return "bull" if lock_price < close_price
        return "draw" if lock_price == close_price
    end

    def get_last_block_order(block_number)
        return 0 if lock_block_number==0
        return lock_block_number - block_number 
    end

 
    def get_detail(block_number)
        @cache_block_number = self.detail.map {|x| [x.block_number,x]}.to_h if @cache_block_number==nil
        return @cache_block_number[block_number]
    end

    def get_count(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bet_count if detail
        return 0
    end

    def get_bull_payout(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bull_payout if detail
        return 0.0
    end

    def get_bear_payout(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bear_payout if detail
        return 0.0
    end

    def get_bull_amount(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bull_amount if detail
        return 0.0
    end

    def get_bear_amount(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bear_amount if detail
        return 0.0
    end


    def get_amount(block_number)
        block_number = lock_block_number if block_number>lock_block_number
        detail = get_detail(block_number)
        return detail.bull_amount+detail.bear_amount if detail
        return 0.0
    end

    def get_wrong_bet(method_name,block_number)
        block_number = lock_block_number if block_number>lock_block_number
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

    def get_address_bet(address)
        if @address_map==nil then
            epoch_last = lock_block_number
            epoch_first = Epoch.where("epoch >= ?",self.epoch-288).order(:epoch).first.start_block_number
            @address_map = Tx.where("?<= block_number and block_number <= ? and (method_name = ? or method_name = ?)",epoch_first,epoch_last,"betBear","betBull").group(:from).count
        end
        @address_map[address] or 0
    end

end
