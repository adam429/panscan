__TASK_NAME__ = "panbot/online/bot_monitor"

load(Task.load("base/database"))
load(Task.load("panbot/simulation/panbot_simulation_runner"))
load(Task.load("panbot/bot/panbot_payout_bot"))
load(Task.load("panbot/panbot_stats"))

load(Task.load("base/render_wrap"))
load(Task.load("base/widget"))
load(Task.load("base/opal_binding"))

# uptime - hourly
# keymetric - hourly
# simulation_diff - hourly

def main()
end
