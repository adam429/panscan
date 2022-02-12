class Block < ApplicationRecord
    has_many :tx, primary_key: "block_number", foreign_key: "block_number"
    has_many :event, primary_key: "block_number", foreign_key: "block_number"
    belongs_to :ar_epoch, primary_key: "epoch", foreign_key: "epoch", class_name: "Epoch"

end
  