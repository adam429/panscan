__TASK_NAME__ = "demo_factorial"



def main()
    database_init(false) # allow to write
    
    block_numbers = __block_begin__..__block_end__
    
    pan_call = PancakePrediction.new
    
    Parallel.map(block_numbers.to_a,in_threads: 10) do |block_number|  
      _log  "#{Time.now} blocks: #{block_number}\n" if block_number%10000==0
      data_import_block(block_number,pan_call.client,pan_call.address,pan_call.function_abi,pan_call.event_abi,pan_call.decoder)
    end
    
end
