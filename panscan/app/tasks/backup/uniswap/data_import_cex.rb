__TASK_NAME__ = "uniswap/data_import_cex"
__ENV__ = "base"

load(Task.load("base/auto-retry"))
load(Task.load("base/auto_split"))
load(Task.load("base/database"))
load(Task.load("base/data_store"))

def main()
    DataStore.init()
    $task.next_schedule_at = Time.now+60*60
    
    swaps = ["ETH-USDT","APE-USDT"]
    # exchange = ["okex","binance"]
    exchange = ["okex"]
    
    exchange.each do |exchange_name|
      swaps.each do |swap_name|
        redis_name = swap_name.gsub(/-/,"")
        
        endpoint = "http://uniswap-v3-tool.funji.club:1924/api/v1/history/#{exchange_name}/kline/#{swap_name}-SWAP/?start_ts=0&end_ts=9999999999999"
    
        url = endpoint
        conn = Faraday.new( url: url )
        response = conn.get() 
        $logger.call url
        $logger.call response.body
        data = JSON.parse(response.body)["data"]["data"]
        
        $logger.call "cex.okex.#{redis_name}.history  len=#{data.size}"
        $logger.call "cex.okex.#{redis_name}.history  size=#{data.to_s.size}"
        $logger.call "cex.okex.#{redis_name}.history  first=#{data.first}"
        DataStore.set("cex.okex.#{redis_name}.history",data)
    
    
        endpoint = "http://uniswap-v3-tool.funji.club:1924/api/v1/history/#{exchange_name}/mark_price/#{swap_name}-SWAP/?start_ts=0&end_ts=9999999999999"
    
        url = endpoint
        conn = Faraday.new( url: url )
        response = conn.get() 
        data = JSON.parse(response.body)["data"]["data"]
        
        $logger.call "cex.okex.#{redis_name}.realtime  len=#{data.size}"
        $logger.call "cex.okex.#{redis_name}.realtime  size=#{data.to_s.size}"
        $logger.call "cex.okex.#{redis_name}.realtime  first=#{data.first}"
        DataStore.set("cex.okex.#{redis_name}.realtime",data)
      end
    end

    nil
end

