__TASK_NAME__ = "uniswap/simulation_v9_dev"
__ENV__ = "ruby3"

load(Task.load("uniswap/simulation_runner_v7"))

def main()
    pool_id = "__pool__"
    exchange = "__exchange__"
    sim_data = "__sim_data__"

    simulation_runner(pool_id,exchange,sim_data,false)
end
