__TASK_NAME__ = "panbot/panbot_stats"

def stats(bet_result,epoch_begin,epoch_end)
    # calc bot stats
    bet_result = bet_result.filter {|x| epoch_begin <= x[:epoch]  and  x[:epoch] <= epoch_end }
    bet_result = bet_result.map { |x| 
        # x[:right_bet] = (x[:bet]==(  x[:bull_payout] > x[:bear_payout]  ? "bull" : "bear"  )) ? 1 : 0
        
        x[:right_bet] = 0
        
        if x[:bet]=="bull" then
            x[:right_bet] = 1 if x[:bull_payout] > 2/0.97
        end
        
        if x[:bet]=="bear" then
            x[:right_bet] = 1 if x[:bear_payout] > 2/0.97
        end
        
        x[:win_bet] = (x[:bet]==x[:bet_result]) ? 1 : 0
        x
    }
    
    bet_result = bet_result.map { |x| 
        x[:return_amt] = -1*x[:amount] + ( x[:win_bet]==1 ? (0.97 * x[:amount] * ( x["#{x[:bet_result]}_payout".to_sym] or 0 ) ) : 0 ) if x[:bet]!="none"
        x
    }

    
    invest_cnt = bet_cnt = bet_epoch = bet_result.filter {|x| x[:bet]!="none"}.count
    all_epoch = epoch_end-epoch_begin+1
    bet_ratio = all_epoch==0 ? 0 : bet_epoch/all_epoch.to_f
    bet_round_payout = bet_epoch==0 ? 0 : bet_result.filter {|x| x[:bet]!="none"}.map { |x| [x[:bull_payout],x[:bear_payout]].max }.sum / bet_epoch.to_f
    bet_bull_cnt = bet_result.filter {|x| x[:bet]=="bull"}.count
    bet_bull_ratio = bet_epoch==0 ? 0 : bet_bull_cnt/bet_epoch.to_f
    
    avg_bet_amt = bet_epoch==0 ? 0 : bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:amount]}.sum / bet_epoch.to_f
    avg_last_block_order = bet_epoch==0 ? 0 : bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:bet_block_order]}.sum / bet_epoch.to_f
    
    right_bet_ratio = bet_epoch==0 ? 0 : bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:right_bet]}.sum / bet_epoch.to_f
    win_bet_ratio = bet_epoch==0 ? 0 : bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:win_bet]}.sum / bet_epoch.to_f
    
    invest_amt = bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:amount]}.sum
    return_amt = bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:return_amt]}.sum
    return_flow = all_epoch==0 ? 0 : return_amt / all_epoch.to_f
    
    max_retrace = 0
    running_return = 0
    bet_result.filter {|x| x[:bet]!="none"}.map {|x| x[:return_amt]}.each do |x|
        running_return = running_return + x
        max_retrace = running_return if running_return<max_retrace
    end
   
    {invest_cnt:invest_cnt,bet_cnt:bet_cnt,bet_epoch:bet_epoch,all_epoch:all_epoch,
    bet_ratio:bet_ratio,bet_round_payout:bet_round_payout,bet_bull_cnt:bet_bull_cnt,bet_bull_ratio:bet_bull_ratio,
    avg_bet_amt:avg_bet_amt,avg_last_block_order:avg_last_block_order,right_bet_ratio:right_bet_ratio,
    win_bet_ratio:win_bet_ratio,invest_amt:invest_amt,return_amt:return_amt,
    return_flow:return_flow,max_retrace:max_retrace}
end

def main()
end