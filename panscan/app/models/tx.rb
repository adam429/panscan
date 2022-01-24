class Tx < ActiveRecord::Base
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"
    has_many :event,  primary_key: "tx_hash", foreign_key: "tx_hash"

end