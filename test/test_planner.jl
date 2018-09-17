using Base.Test
using SCSimulation


fcast_μ = Dict((:C1,i) => 100 for i in 1:5)
fcast_σ = Dict((:C1,i) => 20 for i in 1:5)
custfor = Dict(:M1 => [:C1])
initialinventory = Dict((:M1,i,0) => 200 for i in 1:5)

include("erdirikgraph.jl")
pm = getmodel(getnode(g,1))

d = SCSData([:C1], pm.ext[:products], [:M1], custfor, 84, 7, 0, 0, Delivery[], 14, Dict(),fcast_μ, fcast_σ, 0.5, 0.4, g,
initialinventory, 1, 0)

initialize_forecast(d)
initialize_orders(d, verbose=true)

update_planning_model(d)
