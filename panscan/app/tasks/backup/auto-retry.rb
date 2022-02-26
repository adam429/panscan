__TASK_NAME__ = "auto-retry"

module AutoRetry
    def auto_retry(logger=nil,retry_cnt=12,exception=Net::OpenTimeout)
        begin
            yield
        rescue exception=>e
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

def main
    Object.include AutoRetry
    auto_retry(lambda {|x| _log(x.to_s+"\n")},12,Net::OpenTimeout) { raise Net::OpenTimeout }
end