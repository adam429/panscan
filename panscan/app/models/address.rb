module AutoRetry
  def auto_retry(logger=nil,retry_cnt=12)
      begin
          yield
      rescue Faraday::TimeoutError,Net::OpenTimeout,OpenSSL::SSL::SSLError,JSON::ParserError,Net::ReadTimeout=>e
          if (retry_cnt-=1) > 0 then
              retry_number = 12-retry_cnt
              
              logger.call "sleep #{0.01*(2**retry_number)}" if logger!=nil
              sleep (0.01*(2**retry_number))
              logger.call "retry_cnt #{retry_number} at #{Time.now.to_s}" if logger!=nil
              retry 
          else
              raise e
          end
      end
  end
end

class Address < ApplicationRecord   
    def self.to_graph(addr,level_addr,min_amount=0, max_connect=100,contract=true)

      def self.unify_cex(addr)
        return "CEX Money" if addr.tag=~/Hot Wallet/ 
        return "Bridge" if addr.tag=~/Bridge/ 
        return [addr.tag,addr.addr[-4,4]].join(' @')
      end
          
      addr_list = addr.map {|x| x.to_a[0][1]}.uniq
      level_addr = level_addr.map {|addr| addr.map {|x| x.to_a[0][1]}.uniq}
    
      addr_map = {}
      level_addr.each_with_index {|obj,i|
        cur_map = (obj.map {|x| [x,i] }.to_h)
        addr_map.merge!(cur_map ) {|key, oldval, newval| oldval }
      }
    
      exclude_addr = addr_list.map { |addr|
          [addr, Transfer.where(from:addr).count, Transfer.where(to:addr).count, Transfer.where(from:addr).sum(:amount)/1e18, Transfer.where(to:addr).sum(:amount)/1e18]
      }.filter{ |x| x[2]>max_connect and x[1]>max_connect}
    
      addr_list = addr_list.filter {|x| not exclude_addr.map{|x| x[0]}.include?(x) }
    
      graph = "digraph {\n" +  
        %Q( node [colorscheme=ylgn9] ) + ";\n" +
        exclude_addr.map {|addr| 
          x=Address.find_by_addr(addr[0]);  
          %Q( "#{x.tag ? x.tag + ' @'+x.addr[-4,4] : x.addr }" [shape=doubleoctagon style=filled] ) + ";\n" + 
          %Q( "group @#{x.addr[-4,4]} trans #{addr[1]+addr[2]}"[style=filled] ) + ";\n" +
          %Q( "#{x.tag ? x.tag + ' @'+x.addr[-4,4] : x.addr }" -> "group @#{x.addr[-4,4]} trans #{addr[1]+addr[2]}" [label="#{addr[3].round(2)}"]) + ";\n" +
          %Q( "group @#{x.addr[-4,4]} trans #{addr[1]+addr[2]}" -> "#{x.tag ? x.tag + ' @'+x.addr[-4,4] : x.addr }" [label="#{addr[4].round(2)}"]) + ";\n"
        }.join("") + 
        Transfer.where(from:addr_list).where('"to"<>\'0x18b2a687610328590bc8f2e5fedde3b582a49cda\'').where(contract ? "" : "method_name='Transfer'").where("amount > ?",min_amount * 1e18).map {|x|
          %Q( "#{x.ar_from.tag ? unify_cex(x.ar_from)  : x.from }" -> "#{ x.ar_to.tag ? x.ar_to.tag + ' @'+x.to[-4,4] : x.to}" [label="#{x.method_name == "Transfer" ? (x.amount/1e18).round(2) : ""}#{x.method_name[0,2]=="0x" ? "call" : x.method_name == "Transfer" ? "" : x.method_name }"]) +";\n" +
          %Q( "#{x.ar_from.tag ? unify_cex(x.ar_from) : x.from }" [style=filled color=#{addr_map[x.from] ? addr_map[x.from]+1 : 1}])  +";\n" +
          %Q( "#{ x.ar_to.tag ? unify_cex(x.ar_to)  : x.to}" [style=filled color=#{addr_map[x.to] ? addr_map[x.to]+1 : 1}])  +";\n" 
        }.join("") + 
        Transfer.where(to:addr_list).where('"from"<>\'0x18b2a687610328590bc8f2e5fedde3b582a49cda\'').where(contract ? "" : "method_name='Transfer'").where("amount > ?",min_amount * 1e18).map {|x|
          %Q( "#{x.ar_from.tag ? unify_cex(x.ar_from) : x.from }" -> "#{ x.ar_to.tag ? x.ar_to.tag + ' @'+x.to[-4,4] : x.to}" [label="#{x.method_name == "Transfer" ? (x.amount/1e18).round(2) : ""}#{x.method_name[0,2]=="0x" ? "call" : x.method_name == "Transfer" ? "" : x.method_name }"]) +";\n" +
          %Q( "#{x.ar_from.tag ? unify_cex(x.ar_from) : x.from }" [style=filled color=#{addr_map[x.from] ? addr_map[x.from]+1 : 1}])  +";\n" +
          %Q( "#{ x.ar_to.tag ? unify_cex(x.ar_to)  : x.to}" [style=filled color=#{addr_map[x.to] ? addr_map[x.to]+1 : 1}])  +";\n" 
        }.join("") + "\n}" 
    
        graph =graph.split("\n").uniq.join("\n")
        # graph = graph.split("\n")
        # graph = graph[1,graph.size-2].uniq
        # graph_node = graph.filter {|x| not x=~/label=/}
        # graph_edge = graph.filter {|x| x=~/label=/}
        # graph_edge = graph_edge.map { |x| x.split("=") }
        # graph = (graph_node+graph_edge.map {|x| x.join("-") }).join("\n")
        # puts graph
      url = "https://quickchart.io/graphviz?graph=#{graph.gsub(/\n/,"")}"
      body = Faraday.get(url).body
    end
  

    class << self
      attr_accessor :client,:get_abi,:decoder,:panbot_address
    end
    
    def self.update_tag(address,tag)
      return if address==nil
      
      addr = Address.find_by_addr(address)
      return if addr==nil

      if tag=="" then
        addr.tag = nil
      else  
        addr.tag = tag
      end

      addr.save
    end
    
    def self.load(address)
      return if address==nil
      
      addr = Address.find_by_addr(address)
      return addr if addr
      
      addr = Address.new
      addr.addr = address
      
      is_panbot= self.panbot_address[address]
      addr.is_panbot = is_panbot
      addr.is_contract = self.is_contract(address)
      addr.contract_abi = self.get_abi.call(address) if addr.is_contract 
            
      begin
        addr.save!
      rescue ActiveRecord::RecordNotUnique 
      end
    end
    
    def self.is_contract(address)
      Object.include AutoRetry

      addr = Address.find_by_addr(address)
      return addr.is_contract if addr
      return auto_retry() { self.client.eth_get_code(address,"latest")["result"]!="0x" }
    end

    
  
    def decode_params(input)
      if @function_abi==nil and @event_abi==nil then    
        abi_constructor_inputs, abi_functions, abi_events = Ethereum::Abi.parse_abi(abi)
  
        @function_abi = abi_functions.map do |x|
           ["0x"+x.signature,x]
        end.to_h
  
        @event_abi = abi_events.map do |x|
           ["0x"+x.signature,x]
        end.to_h
      end
            
      if input=='0x' then
        return "Transfer",""
      else
        method_hash = input[0,10]
        # input_data = "0x"+input[10,input.size]  
        if @function_abi!=nil and @function_abi[method_hash] then
          method_hash = @function_abi[method_hash].name
        end
        return method_hash,""
        # method_params = ""
          # begin
          #   method_params = self.class.decoder.decode_arguments(@function_abi[method_hash].inputs,input_data)
          # rescue
          #   method_params = ""
          # end
          # return method_hash,method_params
      end
    end 
    
    def abi
      return @abi if @abi
      if contract_abi == "Contract source code not verified" then
         @abi=[]
         return @abi
      end
      @abi = JSON.parse(contract_abi)
    end
    
    def short_addr
      addr[0,6]+".."+addr[-4,4]
    end

    def calculate_percentile(json, percentile)
      array = JSON.parse(json)
      array.sort[(percentile * array.length).ceil - 1] or 0
    end

    def stats
      """=== stats ===
bet epoch: #{bet_epoch_cnt} / all_epoch: #{Epoch.count} = bet_ratio: #{(bet_epoch_cnt*100.to_f / Epoch.count).round(2)}%

invest_cnt: #{invest_cnt} / bet_cnt: #{bet_cnt} = bet_success_rate: #{ (invest_cnt*100.to_f / bet_cnt).round(2)  }%

bet_bull_cnt: #{bet_bull_cnt} / bet_cnt: #{bet_cnt} = bet_bull_ratio: #{( bet_bull_cnt*100.to_f / bet_cnt).round(2)}%

avg_bet_amt: #{avg_bet_amt.round(4)}
bet_amt_percentile 25%: #{calculate_percentile(bet_amt,0.25).round(4)} | 50%: #{calculate_percentile(bet_amt,0.5).round(4)}| 75%: #{calculate_percentile(bet_amt,0.75).round(4)}

avg_last_block_order: #{avg_last_block_order.round(2)}
right_bet_ratio: #{(right_bet_ratio*100).round(2)}%
win_bet_ratio: #{(win_bet_ratio*100).round(2)}%

invest_cnt: #{invest_cnt} invest_amt: #{invest_amt.round(4)} return_amt: #{return_amt.round(4)}
total_roi: #{ (return_amt*100 / invest_amt).round(2)}% """
    end
end