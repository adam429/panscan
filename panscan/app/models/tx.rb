class Tx < ApplicationRecord
    before_destroy :destroy_callback, prepend: true 
    def destroy_callback
      throws :abort 
    end
      
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"
    has_many :event,  primary_key: "tx_hash", foreign_key: "tx_hash"

    def bet_amount
      # return JSON.parse(self.event.first.params)["amount"] if self.tx_status and (self.method_name=="betBear" or self.method_name=="betBull")
      return amount.to_f/1e18 if self.tx_status and (self.method_name=="betBear" or self.method_name=="betBull")
    end

    
end