__TASK_NAME__ = "research/walken_v1"

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

def init_params()
    levels = [
        {level:1,gems:6,step:6250,days_to_walk:[0,9]}
    ]
end

def main()
    init_params()
    
    RenderWrap.html=
    '''
        <h1>Walken.io Simulation</h1>
        <h2>Parameters</h2>
        <table>
        <tr><td>Token Emission:</td><td> <%= input binding: :token_emission %></td><td><%= slider binding: :token_emission, min:0, max:1600000000, value:800000000 %></td><tr>
        <tr><td>Token Return(%): </td><td><%= input binding: ":token_return_percent = :token_return.to_f/100" %></td><td><%= slider binding: :token_return, min:0, max:1000, value:300 %></td><tr>
        <tr><td>Total Token to Distribute: </td><td><%= text binding: ":token_to_distribute = :token_emission.to_i + :token_emission.to_i * :token_return_percent.to_f" %></td>
        <tr><td>Emission Period(per min):</td><td> <%= input binding: :emission_period %></td><td><%= slider binding: :emission_period, min:0, max:10, value:300 %></td><tr>
        <tr><td>Emission Period(per year): </td><td><%= text binding: ":emission_period_year = :emission_period.to_i * 365.25*24*60" %></td>
        <tr><td>Reward Calculation Period(per min): </td><td> <%= input binding: :reward_calc_period %></td><td><%= slider binding: :reward_calc_period, min:0, max:10, value:1 %></td><tr>
        <tr><td>Average number of competitions: </td><td> <%= input binding: :avg_competition %></td><td><%= slider binding: :avg_competition, min:0, max:50, value:10 %></td><tr>
        <tr><td>Amount of tokens to be distributed(per day): </td><td> <%= text binding: ":avg_token_distribute_day = (1440 / :emission_period_year.to_f*:token_to_distribute.to_i).round(2)" %></td>
        <tr><td>Amount of tokens to be distributed(per calculation period): </td><td> <%= text binding: ":avg_token_distribute_period = (:reward_calc_period.to_i / :emission_period_year.to_f*:token_to_distribute.to_i).round(2)" %></td>
        <tr><td>Lifetime (days): </td><td> <%= input binding: :lifetime %></td><td><%= slider binding: :lifetime, min:0, max:200, value:94 %></td><tr>
        <tr><td>DAU-low:</td><td> <%= input binding: :dau_low %></td><td><%= slider binding: :dau_low, min:0, max:500000, value:2000 %></td><tr>
        <tr><td>DAU-mid:</td><td> <%= input binding: :dau_mid %></td><td><%= slider binding: :dau_mid, min:0, max:500000, value:20000 %></td><tr>
        <tr><td>DAU-high:</td><td> <%= input binding: :dau_high %></td><td><%= slider binding: :dau_high, min:0, max:500000, value:200000 %></td><tr>
        <tr><td>Activity Rate(%):</td><td> <%= input binding: :activity_rate %></td><td><%= slider binding: :activity_rate, min:0, max:100, value:80 %></td><tr>
        </table>
        
        <h4>Target Win</h4>
        <table>
        <tr><td>League</td><td>Pool Share</td><td>Target Win Rate(%)</td><tr>
        <tr><td>1</td><td><%= input binding: :pool_share_1, value:1  %></td><td><%= input binding: :win_rate_1, value:60  %></td><tr>
        <tr><td>2</td><td><%= input binding: :pool_share_2, value:2  %></td><td><%= input binding: :win_rate_2, value:55  %></td><tr>
        <tr><td>3</td><td><%= input binding: :pool_share_3, value:5  %></td><td><%= input binding: :win_rate_3, value:45  %></td><tr>
        <tr><td>4</td><td><%= input binding: :pool_share_4, value:12  %></td><td><%= input binding: :win_rate_4, value:40  %></td><tr>
        <tr><td>5</td><td><%= input binding: :pool_share_5, value:30  %></td><td><%= input binding: :win_rate_5, value:30  %></td><tr>

        </table>
        <h2>Simulation Output</h2>
        <h4>Reward Allocation in Leagues</h4>
        <%= table binding: ":table1 = calc_table1()" %>
    '''
    
    RenderWrap.jsrb=
    '''
        def calc_table1()
            ret = []
            (1..5).each do |i|
                share = $vars["pool_share_#{i}".to_sym].to_f / total_pool_share()
                ret.push({
                    League:i,
                    Share:share.round(2),
                    Total_WLKN: ($vars[:token_to_distribute].to_f * share).round(2),
                    WLKN_per_day: ($vars[:avg_token_distribute_day].to_f * share).round(2),
                    WLKN_per_period: ($vars[:avg_token_distribute_period].to_f * share).round(2),
                })
            end
            return ret
        end
        
        def total_pool_share()
            return $vars[:pool_share_1].to_f + $vars[:pool_share_2].to_f + $vars[:pool_share_3].to_f + $vars[:pool_share_4].to_f + $vars[:pool_share_5].to_f
        end

    '''
    RenderWrap.data
end

