using Base.Test
using SCSimulation
using DataFrames
using Scheduling
using Plasmo
using JuMP

#srand(12345)

fcast_μ = Dict((:C1,i) => 100 for i in [:P1,:P2])
fcast_σ = Dict((:C1,i) => 20 for i in [:P1,:P2])
custfor = Dict(:M1 => [:C1])
initialinventory = Dict((:M1,i,0) => 200 for i in [:P1,:P2])
ptype = Dict(:P1 => :MTS,
             :P2 => :MTS)
tk = Dict(:P1 => :Tk_P1, :P2 => :Tk_P2)

include("planning.jl")
include("kondili.jl")
n.backlogpenalty = [1 for t in 1:n.periods]
m = generatemodelUOPSS!(n, objective=[:minbacklog, :minbatches])
JuMP.setsolver(m,GurobiSolver(MIPGap=0.1))

g = ModelGraph()
Plasmo.setsolver(g, GurobiSolver(MIPGap=0.1))
n1 = add_node(g, pm)
n2 = add_node(g, m)
add_edge(g, n1, n2)
@linkconstraint(g, [p in products, t in periods], n1[:inv][:M1,p,t] == n2[:invtgt][tk[p],p,42t])
@linkconstraint(g, [p in products, t in periods], n1[:x][:M1,p,t] == n2[:prodtgt][p,t])

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
            1344,
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

@test getvalue(D[:C1,:P1,1]) > 0
@test getvalue(inv[:M1,:P1,0]) > 0

update_scheduling_models(d)
sm = getmodel(getnode(d.graph,2))
Ds = getindex(sm,:D)
#@test getlowerbound(Ds[:P1,11]) > 0

mf = create_jump_graph_model(d.graph)
setattribute(d.graph, :monolith, mf)
JuMP.setsolver(mf, getsolver(d.graph))


solve(mf)
monolith_to_graph(mf, d.graph)


@test m.colVal[1] != NaN

d.currentperiod = 168

update_orders(d, verbose=true)
#=
update_scheduling_models(d)
status = solve(sm)

@test status == :Optimal
=#
