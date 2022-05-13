__TASK_NAME__ = "uniswap/simulation_v8_dev"
__ENV__ = "base"

load(Task.load("uniswap/simulation_runner_v5"))

def main()
    # BigDecimal.limit(32)
    # RenderWrap.before_jsrb("library.bigdecimal","require 'bigdecimal'\n require 'bigdecimal/util'\n require 'bigdecimal/math'\n")
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("uniswap/uniswapv3_v2::(UniswapV3,Pool)"))
    RenderWrap.load(Task.load("uniswap/uniswapv3_v2::(UniswapV3,Pool)"))
    RenderWrap.load(Task.load("uniswap/dex_v2::Dex"))
    RenderWrap.load(Task.load("uniswap/cex::Cex"))
    RenderWrap.load(Task.load("uniswap/bot::Bot"))
    RenderWrap.load(Task.load("uniswap/simulation_class_v3::Simulation"))


    pool_id = "__pool__"
    sim_data = "__sim_data__"

    simulation_runner(pool_id,sim_data,false)
end
