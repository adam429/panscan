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
        @address = params[:id].downcase
        @addr = Address.find_by_addr(@address)

        @pagy, @tx = pagy(Transfer.where('"from" = ? or "to"=?',@address,@address).order(:block_number))        
    end

    def address
        @address = params[:id].downcase
        @addr = Address.find_by_addr(@address)


        @pagy, @tx = pagy(Tx.where('"from" = ?',@address).where("method_name=? or method_name=?",'betBull','betBear').order(:block_number))        

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

    def stats_clean_cache
        Cache.destroy_all
        
        redirect_to "/stats"
    end

    def address_tag
        address = params[:id]
        tag = params[:tag]
        Address.update_tag(address,tag)
        redirect_to "/transfer/address/#{address}"
    end

    def top_contract
        @top500 = Transfer.top_transaction
        @top500 = @top500.filter {|x| Address.is_contract(x[0])}
    end

    def top_transfer
        @top500 = Transfer.top_transfer
        @top500 = @top500.filter {|x| not Address.is_contract(x[0])}
    end


    def address_top
        @name = params[:name]
        @prev = params[:prev]
        @prev_order = params[:prev_order]
        @where = params[:where]

        if @name==nil then
            @prev = "return_amt"
            @prev_order = "desc"
        else
            if @prev== @name then
                @prev_order =  @prev_order=="desc" ? "asc" : "desc"
            else
                @prev = @name
                @prev_order = "desc"                
            end
        end
        @address = Address.where(params[:where]).where(is_panbot:true).order("#{@prev} #{@prev_order}").order(:id)
        @address = @address.where("#{@prev} <> ?",Float::NAN) if @prev=="avg_bet_amt" or @prev=="avg_last_block_order" or @prev=="right_bet_ratio" or @prev=="win_bet_ratio"
        @pagy, @address = pagy(@address)        

    end

    def address_group
        @name = params[:name]
        @prev = params[:prev]
        @prev_order = params[:prev_order]
        @where = params[:where]

        if @name==nil then
            @prev = "return_amt"
            @prev_order = "desc"
        else
            if @prev== @name then
                @prev_order =  @prev_order=="desc" ? "asc" : "desc"
            else
                @prev = @name
                @prev_order = "desc"                
            end
        end

        @group_name = params[:group]
        
        @group = Address.where("tag LIKE ?","#{@group_name}%").where(params[:where]).where(is_panbot:true).order("#{@prev} #{@prev_order}").order(:id)

        @return_amt = @group.sum(:return_amt)
        @invest_amt = @group.sum(:invest_amt)
        
        @group = @group.where("#{@prev} <> ?",Float::NAN) if @prev=="avg_bet_amt" or @prev=="avg_last_block_order" or @prev=="right_bet_ratio" or @prev=="win_bet_ratio"
        @pagy, @address = pagy(@group)        
    end

    def address_group_top
        @group = Address.where("tag is not null").where(is_panbot:true).map {|x| x.tag.split(" ")[0] };
        @group = @group.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.to_a.sort{|x,y|-1*(x[1]<=>y[1])}
    end

    def index
    end
end
