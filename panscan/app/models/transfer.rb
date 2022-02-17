class Transfer < ApplicationRecord
    belongs_to :ar_from, primary_key: "addr", foreign_key: "from", class_name: "Address"
    belongs_to :ar_to, primary_key: "addr", foreign_key: "to", class_name: "Address"
    belongs_to :tx, primary_key: "tx_hash", foreign_key: "tx_hash"
    belongs_to :block, primary_key: "block_number", foreign_key: "block_number"

    def self.top_transaction()
        top500 = Cache.get("Transfer-top_address")
        if top500==nil then
            all_addr = Transfer.select(:from,:to).all.map {|x| [x.from, x.to]};
            all_addr = all_addr.flatten
            all_addr = all_addr.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
            all_addr = all_addr.to_a.sort {|x,y| -1*(x[1]<=>y[1])}
            top500 = all_addr[0,500]        
            Cache.set("Transfer-top_address",top500)
        end
        return top500
    end    

    def self.top_transfer()
        top500 = Cache.get("Transfer-top_transfer")
        if top500==nil then
            all_addr = Transfer.where(method_name:"Transfer").select(:from,:to).all.map {|x| [x.from, x.to]};
            all_addr1 = all_addr.flatten
            all_addr1 = all_addr1.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
            all_addr1 = all_addr1.to_a.sort {|x,y| -1*(x[1]<=>y[1])}
            top500 = all_addr1[0,500]    
            top = top500.map { |y|
                [y[0],y[1],all_addr.filter{ |x| x[0]==y[0]}.count, all_addr.filter{ |x| x[1]==y[0] }.count]
            }
            nil
            Cache.set("Transfer-top_transfer",top)
        end
        return top500
    end    
end