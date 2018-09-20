using JuMP
using Gurobi

plants = [:M1]
products = [:P1, :P2]
periods = 1:8
customers = [:C1]
TC = Dict((:M1,:C1) => 0.01)
HC= 0.02

function planning()
    m = Model(solver=GurobiSolver(MIPGap=0.1))
    @variable(m, x[j in plants, p in products, t in periods] >= 0)
    @variable(m, inv[j in plants, p in products, t in 0:periods[end]] >= 0)
    @variable(m, f[j in plants, k in customers, p in products, t in periods] >= 0)
    @variable(m, D[k in customers, p in products, t in periods] >= 0)

    @constraint(m, dem[k in customers, p in products, t in periods], sum(f[j,k,p,t] for j in plants) == D[k,p,t])
    @constraint(m, invbal[j in plants, p in products, t in periods], inv[j,p,t] == inv[j,p,t-1] + x[j,p,t] - sum(f[j,k,p,t] for k in customers) )

    @expression(m, transportationCost, sum(TC[j,k]*f[j,k,p,t] for (j,k,p,t) in keys(f)))
    @expression(m, inventoryCost, sum(HC*inv[j,p,t] for (j,p,t) in keys(inv)))
    @expression(m, productionCost, AffExpr(0))
    @objective(m, Min, transportationCost + inventoryCost + productionCost)

    m.ext[:customers] = customers
    m.ext[:plants] = plants
    m.ext[:products] = products
    m.ext[:numperiods] = length(periods)
    m.ext[:periodmap] = Dict()

    return m

end

pm = planning()
