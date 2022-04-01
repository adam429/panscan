__TASK_NAME__ = "base/auto-retry"

require 'faraday'

module AutoRetry
    def auto_retry(logger=nil,retry_cnt=12)
        begin
            yield
        rescue Faraday::TimeoutError,Net::OpenTimeout,OpenSSL::SSL::SSLError,JSON::ParserError,Net::ReadTimeout,Errno::ECONNRESET,Errno::ECONNREFUSED, EOFError=>e
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
    auto_retry(lambda {|x| _log(x.to_s+"\n")},12) { raise Net::OpenTimeout }
end