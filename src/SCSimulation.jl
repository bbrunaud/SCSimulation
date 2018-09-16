
module SCSimulation

using ResumableFunctions
using Distributions

export SCSData, Delivery,
        # Demand Planner
        demand_planner, initialize_forecast!, update_forecast!,
        # Logistics Planner
        logistics_planner, initialize_orders!, update_orders!

include("types.jl")
include("demand_planner.jl")
include("logistics_planner.jl")


end
