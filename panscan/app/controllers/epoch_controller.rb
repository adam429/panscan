class EpochController < ApplicationController
    def foo
    end

    def web_console
         console
    end

    def epoch
        @epoch      = Epoch.find_by_epoch(params[:id].to_i)
        @epoch_next = Epoch.find_by_epoch(params[:id].to_i+1)
    end

    def transfer
        @block_number = params[:id].to_i

        @pagy, @transfer = pagy(Transfer.where(block_number:@block_number))        
    end

    def trans_addr
        @address = params[:id]
        @addr = Address.find_by_addr(@address)

        @pagy, @tx = pagy(Transfer.where('"from" = ? or "to"=?',@address,@address).order(:block_number))        
    end

    def address
        @address = params[:id]
    
        @tx = Tx.where('"from" = ?',@address).where("method_name=? or method_name=?",'betBull','betBear').order(:block_number)

        @tx_map = {}
        Event.where(tx_hash:@tx.map {|x| x.tx_hash}).each {|event|
            amount = JSON.parse(event.params)["amount"]
           @tx_map[event.tx_hash] = [
               event.name,
               amount,
               event.block_number
           ]
        }        
        
        @epoch_map = {}
        
        tx_block_map = @tx.map {|x| [x.tx_hash,x.block_number]}.to_h
        block_epoch_map = Block.where(block_number:@tx.map {|x| x.block_number}).map {|x| [x.block_number,x.epoch]}.to_h
        epoch_ar_map = Epoch.where(epoch:block_epoch_map.to_a.map{|x| x[1]}).map {|x| [x.epoch,x]}.to_h

        tx_block_map.each { |k,v| 
            @epoch_map[k] = epoch_ar_map[block_epoch_map[v]]
        }
    end

    def all
        @epoch_count = Epoch.count
        @pagy, @epoch = pagy(Epoch.order("epoch desc"))        
    end
end
