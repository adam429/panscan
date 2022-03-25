class EpochController < ApplicationController
    def foo
    end

    def log
        query = Log.order(:id)
        query = query.where("worker like ? or log like ?",params[:q],"%#{params[:q]}%") if params[:q]
        query = query.where("id >= ?",params[:id]) if params[:id]
        query = query.where("worker = ?",params[:worker]) if params[:worker]
        @pagy, @log = pagy(query)        
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
        Cache.where("key like ?","%-count").map {|x| x.delete}
        
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

    def address_group_graph
        @group_name = params[:group]
        @min_amount = (params[:min_amount] or 10).to_i
        @max_connect = (params[:max_connect] or 100).to_i

        group = Address.where("tag LIKE ?","#{@group_name}%").map {|x| {"input"=>x.addr}}
        @graph = Address.to_graph(group,group,@min_amount,@max_connect,true) 
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

        data = Cache.get("Group-#{@group_name}-stats")
        if data then
            @bet_epoch_cnt = data["bet_epoch_cnt"]
            @invest_cnt = data["invest_cnt"]
            @bet_cnt = data["bet_cnt"]
            @bet_bull_cnt = data["bet_bull_cnt"]
            @bet_bear_cnt = data["bet_bear_cnt"]
            @avg_last_block_order = data["avg_last_block_order"]
            @avg_bet_amt = data["avg_bet_amt"]
            @right_bet_ratio = data["right_bet_ratio"]
            @win_bet_ratio = data["win_bet_ratio"]
            @return_amt = data["return_amt"]
            @invest_amt = data["invest_amt"]
            @first_tx_time = data["first_tx_time"]
            @last_tx_time = data["last_tx_time"]
        else
            @bet_epoch_cnt = @group.sum(:bet_epoch_cnt)
            @invest_cnt = @group.sum(:invest_cnt)
            @bet_cnt = @group.sum(:bet_cnt)
            @bet_bull_cnt = @group.sum(:bet_bull_cnt)
            @bet_bear_cnt = @group.sum(:bet_bear_cnt)

            @avg_last_block_order = @group.filter{|x| not x.avg_last_block_order.nan? }.map {|x| x.avg_last_block_order * x.invest_cnt }.sum / @invest_cnt
            @avg_bet_amt = @group.filter{|x| not x.avg_bet_amt.nan? }.map {|x| x.avg_bet_amt * x.invest_cnt }.sum /  @invest_cnt
            @right_bet_ratio = @group.filter{|x| not x.right_bet_ratio.nan? }.map {|x| x.right_bet_ratio * x.bet_cnt }.sum / @bet_cnt
            @win_bet_ratio = @group.filter{|x| not x.win_bet_ratio.nan? }.map {|x| x.win_bet_ratio * x.bet_cnt }.sum /  @bet_cnt

            @return_amt = @group.sum(:return_amt)
            @invest_amt = @group.sum(:invest_amt)
            @first_tx_time = Tx.where(from:@group.map {|x| x.addr}).order(:block_time).first.block_time.to_formatted_s(:db)
            @last_tx_time = Tx.where(from:@group.map {|x| x.addr}).order(:block_time).last.block_time.to_formatted_s(:db)

            data={bet_epoch_cnt:@bet_epoch_cnt, invest_cnt:@invest_cnt,
                bet_cnt:@bet_cnt,bet_bull_cnt:@bet_bull_cnt,bet_bear_cnt:@bet_bear_cnt,avg_last_block_order:@avg_last_block_order,
                avg_bet_amt:@avg_bet_amt,right_bet_ratio:@right_bet_ratio,win_bet_ratio:@win_bet_ratio,
                return_amt:@return_amt,invest_amt:@invest_amt,first_tx_time:@first_tx_time,last_tx_time:@last_tx_time
            }
            Cache.set("Group-#{@group_name}-stats",data)
        end

        
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
