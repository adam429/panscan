class Event < ApplicationRecord
    before_destroy :destroy_callback, prepend: true 
    def destroy_callback
      throws :abort 
    end
  
    belongs_to :tx, primary_key: "tx_hash", foreign_key: "tx_hash"
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"
end
  