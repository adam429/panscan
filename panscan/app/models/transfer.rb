class Transfer < ApplicationRecord
    def self.top_address()
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
end