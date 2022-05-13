__TASK_NAME__ = "uniswap/data_import_v0"

require 'faraday'
require 'faraday/net_http'
require 'bigdecimal'
require 'bigdecimal/util'

class GraphQuery
    SubGraph_EndPoint ="https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3"
    attr_accessor :pool,:token0_decimal,:token1_decimal, :cur_price

    def number(num,precision=Float::DIG)
        num.to_f
        # BigDecimal(num,precision)
    end
    
    def initialize(pool,token0_decimal=18,token1_decimal=18)
        @pool = pool
        @token0_decimal = token0_decimal
        @token1_decimal = token1_decimal
        @cur_price = nil
        RenderWrap.before_jsrb("library.bigdecimal","require 'bigdecimal'\n require 'bigdecimal/util'\n")
    end
    
    def tick2price(tick)
        # $logger.call "tick = #{tick}"
        number(1.0001,Float::DIG)**tick * 10 ** (@token0_decimal-@token1_decimal)
    end
    
    def graph_query(query)
        conn = Faraday.new( url: GraphQuery::SubGraph_EndPoint )
        response = conn.post() do |req|
          req.body = {query:query}.to_json
        end
        data = JSON.parse(response.body)["data"]
    end
    
    def ticks()
        query =  """ {
            ticks(first: 1000, skip: 0, where: { poolAddress: \"#{@pool}\" }, orderBy: tickIdx) {
              tickIdx
              liquidityNet
              price0
              price1
            }
          }
        """
        ret = graph_query(query)["ticks"]
        raise "NotImplement: Page Buffer Reading from Graph" if ret.size==1000

        return ret
    end
    
    def pool_hour_datas()
        query = """
        {
            poolHourDatas(skip: 0, first:1000, orderBy: periodStartUnix, orderDirection: desc, where:{pool: \"#{@pool}\" }) {
              periodStartUnix
            	token0Price
            	token1Price
            	open
                high
                low
                close
            }
        }
        """  
        graph_query(query)["poolHourDatas"]
    end
    
    def pool_day_datas()
        query = """
        {
            poolDayDatas(skip: 0, first:45, orderBy: date, orderDirection: desc, where:{pool: \"#{@pool}\" }) {
              date
              token0Price
              token1Price
        	  volumeToken0
        	  volumeToken1
        	  volumeUSD
              open
              high
              low
              close
            }
          }        
        """  
        graph_query(query)["poolDayDatas"]
    end    

    def volume()
        pool_day_datas = pool_day_datas()
        ret = []
        
        pool_day_datas.map {|x| 
            {
                time: Time.at(x["date"]),
                volumeToken0: number(x["volumeToken0"]),
                volumeToken1: number(x["volumeToken1"]),
            }
        }.each do |x|
            24.times do |t|
                ret.push ( {time:x[:time]-t*3600, volumeToken0:x[:volumeToken0]/24, volumeToken1:x[:volumeToken1]/24} )
            end
        end
        ret
    end
    
    def price()
        pool_hour_datas = pool_hour_datas()
        ret = pool_hour_datas.map {|x| 
            {time: Time.at(x["periodStartUnix"]),
            open: 1/number(x["open"]),
            high: 1/number(x["high"]),
            low: 1/number(x["low"]),
            close: 1/number(x["close"])}
        }
        @cur_price = ret[0][:close]
        ret
    end
    
    def liquidity_pool()
        ticks = ticks()
        
        bins=[]
        liquidity = number(0);
        
        (0..ticks.size - 2).map do |i|
            # $logger.call "liquidity_pool #{i} / #{ticks.size - 2}"
            # $logger.call (ticks[i]["liquidityNet"])
            liquidity += number(ticks[i]["liquidityNet"])
            # $logger.call (liquidity)
        
            lower_price = tick2price(number(ticks[i]["tickIdx"]))
            # $logger.call (lower_price)
            upper_price = tick2price(number(ticks[i+1]["tickIdx"]))
            # $logger.call (upper_price)
            
            if @cur_price/2 <= lower_price and upper_price<=@cur_price*2 then
                bins.push({
                    price_a: lower_price,
                    price_b: upper_price,
                    l: liquidity,
                    sender: nil
                })
            end
        end
        bins
    end
end

require 'faraday'
require 'faraday/net_http'


def get_remote_data(begin_id= 0, end_id=100)
    pool = "0x5859ebe6fd3bbc6bd646b73a5dbb09a5d7b6e7b7"
    endpoint = "https://uniswap.funji.club/api/v1/uni/txn/"

    data = []
    last_id = begin_id
    
    loop do
        $logger.call last_id
        break if last_id>end_id
    
        conn = Faraday.new( url: endpoint+pool+"?page_size=500&last_id="+last_id.to_s )
        
        response = conn.get() do |req|
            req["Authorization"] = "Bearer ff691328bb4547dcb5517baa23ab75c6"
        end
    
        # puts response.body
        slice = JSON.parse(response.body)["data"]
        
        break if slice.size==0
    
        data = data + slice
        
        last_id = slice[-1]["id"]
    end
    
    data
end

def main
    get_remote_data()
end