using Base.Test
using SCSimulation
using DataFrames

srand(12345)

fcast_μ = Dict((:C1,i) => 100 for i in 1:5)
fcast_σ = Dict((:C1,i) => 20 for i in 1:5)
custfor = Dict(:M1 => [:C1])
initialinventory = Dict((:M1,i,0) => 200 for i in 1:5)
ptype = Dict(1 => :MTS,
             2 => :MTS,
             3 => :MTS,
             4 => :MTO,
             5 => :MTO)

include("erdirikgraph.jl")
pm = getmodel(getnode(g,1))

d = SCSData([:C1],
            pm.ext[:products],
            [:M1],
            custfor,
            ptype,
            1344,
            168,
            0,
            0,
            DataFrame(plant=[],product=[],amount=[],date=[], delivered=[], actual_date=[], status=[]),
            336,
            4,
            Dict(),
            fcast_μ,
            fcast_σ,
            0.5,
            0.4,
            g,
            initialinventory,
            1,
            0)

initialize_forecast(d)
initialize_orders(d, verbose=true)

update_planning_model(d)
m = getmodel(getnode(d.graph,1))
D = getindex(m, :D)
inv = getindex(m, :inv)

@test getvalue(D[:C1,1,1]) > 0
@test getvalue(inv[:M1,1,0]) > 0

mf = create_jump_graph_model(d.graph)
setattribute(d.graph, :monolith, mf)
setsolver(mf, getsolver(d.graph))

solve(mf)
monolith_to_graph(mf, d.graph)
m = getmodel(getnode(d.graph,1))

@test m.colVal[1] != NaN
