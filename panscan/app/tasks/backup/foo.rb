__TASK_NAME__ = "foo"

load(Task.load("base/data_store"))

def main()
    DataStore.init
    
    pool_id = "0xac4b3dacb91461209ae9d41ec517c2b9cb1b7daf"
    block_to_time = DataStore.get("uniswap.#{pool_id}.time_table")
    
    block_to_time = block_to_time.map {|x| [x[0],x[1],Time.at(x[1]).utc.to_s] }
    
    block_to_time.each_with_index {|x,i|
        if (block_to_time[i+1][1]-block_to_time[i][1])<=10 and (block_to_time[i+1][1]-block_to_time[i][1])>0 then
            $logger.call i
            $logger.call block_to_time[i]
            $logger.call block_to_time[i+1]
            break
        end
    }

    $logger.call (block_to_time.size)
    $logger.call (block_to_time[0,10])


end

