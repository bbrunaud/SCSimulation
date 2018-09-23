using Base.Test
using SCSimulation
using DataFrames
using Scheduling
using Plasmo
using JuMP
using Distributions


#srand(12345)

fcast_μ = Dict((:C1,i) => 100 for i in [:P1,:P2])
fcast_σ = Dict((:C1,i) => 20 for i in [:P1,:P2])
custfor = Dict(:M1 => [:C1])
ptype = Dict(:P1 => :MTS,
             :P2 => :MTS)
tk = Dict(:P1 => :Tk_P1, :P2 => :Tk_P2)

include("planning.jl")
include("kondili.jl")
initialinventory = Dict((:M1,i,0) => 50.0 for i in n.materials[n.name])
for p in [:A, :B, :C]
    initialinventory[:M1,p,0] = 20000
end
n.backlogpenalty = [1 for t in 1:n.periods]
m = generatemodelUOPSS!(n, objective=[:minbacklog, :minbatches])
JuMP.setsolver(m,GurobiSolver(MIPGap=0.1))

g = ModelGraph()
Plasmo.setsolver(g, GurobiSolver(MIPGap=0.1))
n1 = add_node(g, pm)
n2 = add_node(g, m)
setattribute(n2,:network, n)
ct = DataFrame(DataFrame(Task=[], Material=[], Time=[], Sense=[], Coefficient=[]))
for (key, value) in n.coefficient
         push!(ct, vcat(key...,value))
end
setattribute(n2,:coefftable, ct)

add_edge(g, n1, n2)
@linkconstraint(g, [p in products, t in periods], n1[:inv][:M1,p,t] == n2[:invtgt][tk[p],p,42t])
@linkconstraint(g, [p in products, t in periods], n1[:x][:M1,p,t] == n2[:prodtgt][p,t])

# Generate Fails
fails = DataFrame(Plant=[], Unit=[], Start=[], End=[])
duration = Exponential(2)
spacing = Normal(200,50)
failstart = 0
failend = 0
while true
    failstart = failend + Int(round(rand(spacing),0))
    failduration = Int(round(rand(duration),0))
    failend = failstart + failduration
    if failend > 168*52
        break
    end
    unit = rand(n.units)
    if failduration > 0
        push!(fails, [:M1,unit,failstart, failend])
    end
end

unitstatus = Dict((:M1, u) => :Available for u in n.units)

d = SCSData([:C1],
            pm.ext[:products],
            n.materials[n.name],
            [:M1],
            Dict(:M1 => n.units),
            custfor,
            ptype,
            1344,
            168,
            0,
            0,
            DataFrame(Number=[], Plant=[], Product=[], Amount=[], Date=[], Delivered=[], ActualDate=[], Status=[]),
            DataFrame(Order=[], Plant=[], Task=[], Unit=[], Start=[], Duration=[], End=[], Size=[], ActualStart=[], ActualDuration=[], ActualEnd=[], Perturbed=[], Status=[]),
            DataFrame(Number=[], Order=[], Plant=[], Task=[], Unit=[], Material=[], Amount=[]),
            DataFrame(Number=[], Order=[], Plant=[], Task=[], Unit=[], Material=[], Amount=[], ActualAmount=[]),
            fails,
            unitstatus,
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
            0,
            1000000,
            1000,
            1000,
            2000)

#runsimu(d, 500, verbose=true)
