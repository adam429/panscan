class EpochController < ApplicationController
    def foo
    end

    def epoch
        @epoch = Epoch.find_by_epoch(params[:id])
    end

    def address
        @address = params[:id]

        @tx = Tx.where("`from` = ?",@address).where("method_name=? or method_name=?",'betBull','betBear').order(:block_number)

        @tx_map = {}
        Event.where(tx_hash:@tx.map {|x| x.tx_hash}).each {|event|
            amount = JSON.parse(event.params)["amount"]
           @tx_map[event.tx_hash] = [
               event.name,
               amount,
               event.block_number
           ]
        }                    

        
    end

    def all
        @epoch = Epoch.order("epoch").all
    end
end
