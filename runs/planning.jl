using JuMP
using Gurobi

plants = [:M1]
products = [:P1, :P2]
periods = 1:8
customers = [:C1]
TC = Dict((:M1,:C1) => 0.01)
HC= 0.02

function planning()
    m = Model(solver=GurobiSolver(MIPGap=0.01, Threads=1))
    @variable(m, x[j in plants, p in products, t in periods] >= 0)
    @variable(m, inv[j in plants, p in products, t in 0:periods[end]] >= 0)
    @variable(m, f[j in plants, k in customers, p in products, t in periods] >= 0)
    @variable(m, D[k in customers, p in products, t in periods] >= 0)
    @variable(m, ud[k in customers, p in products, t in periods] >= 0)
    @variable(m, udt[p in products, t in periods] >= 0)

    @constraint(m, dem[k in customers, p in products, t in periods], sum(f[j,k,p,t] for j in plants) + ud[k,p,t] == D[k,p,t])
    @constraint(m, invbal[j in plants, p in products, t in periods], inv[j,p,t] == inv[j,p,t-1] + x[j,p,t] - sum(f[j,k,p,t] for k in customers) )
    @constraint(m, conudt[p in products, t in periods], udt[p,t] == sum(ud[k,p,t] for k in customers))

    @expression(m, transportationCost, -10*sum(f[j,k,p,t] for (j,k,p,t) in keys(f)))
    @expression(m, inventoryCost, sum(HC*inv[j,p,t] for (j,p,t) in keys(inv)))
    @expression(m, productionCost, AffExpr(0))
    @expression(m, unsatisfied, -7*sum(ud[k,p,t] for k in customers for p in products for t in periods))
    @objective(m, Min, transportationCost + inventoryCost + productionCost + unsatisfied)

    m.ext[:customers] = customers
    m.ext[:plants] = plants
    m.ext[:products] = products
    m.ext[:numperiods] = length(periods)
    m.ext[:periodmap] = Dict()
    m.ext[:sales] = transportationCost
    m.ext[:redirected] = unsatisfied
    m.ext[:inventoryCost] = inventoryCost

    return m

end
