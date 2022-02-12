class Tx < ApplicationRecord      
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"
    has_many :event,  primary_key: "tx_hash", foreign_key: "tx_hash"
    belongs_to :transfer, primary_key: "tx_hash", foreign_key: "tx_hash"
    belongs_to :ar_from, primary_key: "addr", foreign_key: "from", class_name: "Address"
    belongs_to :ar_to, primary_key: "addr", foreign_key: "to", class_name: "Address"

    def bet_amount
      # return JSON.parse(self.event.first.params)["amount"] if self.tx_status and (self.method_name=="betBear" or self.method_name=="betBull")
      return amount.to_f/1e18 if self.tx_status and (self.method_name=="betBear" or self.method_name=="betBull")
    end

    
end