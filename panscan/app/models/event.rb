class Event < ActiveRecord::Base
    belongs_to :tx, primary_key: "tx_hash", foreign_key: "tx_hash"
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"
end
  