using JuMP
using Gurobi
using Plasmo
using PlasmoAlgorithms

include("P5T24data.jl")

function plansched(;reverse=false,gap=0.005)
products = 1:5
periods = 1:4
plants = [:M1]
customers = [:C1]
slots = 1:length(products)

m = Model(solver=GurobiSolver(MIPGap=gap))

@variable(m, Θ[i in products, t in periods] >= 0)
@variable(m, x[i in products, t in periods] >= 0)
@variable(m, inv[p in plants, i in products, t in 0:periods[end]] >= 0)
@variable(m, invo[p in plants, i in products, t in periods] >= 0)
@variable(m, s[i in products, t in periods] >= 0)
@variable(m, D[c in customers, i in products, t in periods] >= 0)
@variable(m, area[i in products, t in periods] >= 0)

for i in products
    JuMP.fix(inv[:M1, i,0], INVI[i])
    for t in periods
        JuMP.fix(D[:C1,i,t], Dem[i,t])
    end
end

# B) Assignment and Processing Times
@constraint(m, eq4b[i in products, t in periods], x[i,t] == R[i]*Θ[i,t])
@constraint(m, eq28[t in periods], sum(Θ[i,t] for i in products) <= H[t])

# E) Inventory
@constraint(m, eq11a[i in products], inv[:M1,i,1] == inv[:M1,i,0] + x[i,1])
@constraint(m, eq11b[i in products, t in periods;t>1], inv[:M1,i,t] == invo[:M1,i,t-1] + x[i,t])
@constraint(m, eq12[i in products, t in periods], invo[:M1,i,t] == inv[:M1,i,t] - s[i,t])
@constraint(m, eq13[i in products, t in periods;t>1], area[i,t] >= (invo[:M1,i,t-1] + x[i,t])*H[t])
@constraint(m, eq13b[i in products], area[i,1] >= (inv[:M1,i,0] + x[i,1])*H[1])

# Demand Satisfaction
@constraint(m, eqsat[i in products, t in periods], s[i,t] >= D[:C1,i,t])

# A) Objective Function
@expression(m, sales, sum(P[i]*s[i,t] for i in products, t in periods))
@expression(m, invcost, CInv*sum(area[i,t] for t in periods, i in products) )
@expression(m, opercost, sum(COper[i]*x[i,t] for i in products, t in periods) )

@objective(m, Min, -sales + invcost + opercost)

m.ext[:customers] = customers
m.ext[:plants] = plants
m.ext[:products] = products
m.ext[:numperiods] = length(periods)
m.ext[:periodmap] = Dict()

##
## SCHEDULING MODEL
##
s = Model(solver=GurobiSolver(MIPGap=gap))

@variable(s, w[i in products, l in slots, t in periods], Bin)
@variable(s, Θl[i in products, l in slots, t in periods] >= 0)
@variable(s, xl[i in products, l in slots, t in periods] >= 0)
@variable(s, Θ[i in products, t in periods] >= 0)
@variable(s, x[i in products, t in periods] >= 0)
@variable(s, z[i in products, k in products, l in slots, t in periods] >= 0)
@variable(s, te[l in slots, t in periods] >= 0)
@variable(s, ts[l in slots, t in periods] >= 0)
@variable(s, trt[i in products, k in products, t in periods] >= 0)

# Bounds
setupperbound(ts[1,1], 0)
for t in periods
  setupperbound(te[slots[end],t], HT[t])
  if t < periods[end]
    setlowerbound(ts[1,t+1], HT[t])
    setupperbound(ts[1,t+1], HT[t])
  end
end

# B) Assignment and Processing Times
@constraint(s, eq2[l in slots, t in periods], sum(w[i,l,t] for i in products) == 1 )
@constraint(s, eq3a[i in products, l in slots, t in periods], Θl[i,l,t] <= H[t]*w[i,l,t])
@constraint(s, eq3b[i in products, t in periods], Θ[i,t] == sum(Θl[i,l,t] for l in slots))
@constraint(s, eq4a[i in products, l in slots, t in periods], xl[i,l,t] == R[i]*Θl[i,l,t])
@constraint(s, eq4b[i in products, t in periods], x[i,t] == sum(xl[i,l,t] for l in slots))

# C) Transitions
@constraint(s, eq5[i in products, k in products, l in slots, t in periods;l<slots[end] && i!=k], z[i,k,l,t] >= w[i,l,t] + w[k,l+1,t] - 1)

# D) Timing Relations
@constraint(s, eq6[l in slots, t in periods], te[l,t] == ts[l,t] + sum(Θl[i,l,t] for i in products) + sum(τ[i,k]*z[i,k,l,t] for i in products, k in products) )
@constraint(s, eq7[i in products, k in products, t in periods; t<periods[end] && i!=k], trt[i,k,t] >= w[i,slots[end],t] + w[k,slots[1],t+1] - 1)
@constraint(s, eq8[t in periods;t<periods[end]], te[slots[end],t] + sum(τ[i,k]*trt[i,k,t] for i in products, k in products) == ts[slots[1],t+1])
@constraint(s, eq9[l in slots, t in periods;l<slots[end]], te[l,t] == ts[l+1,t])
@constraint(s, eq10[t in periods], te[slots[end], t] <= HT[t])

# A) Objective Function
@expression(s, transslotcost, sum(CTrans[i,k]*z[i,k,l,t] for i in products, k in products, l in slots, t in periods) )
@expression(s, transperiodcost, sum(CTrans[i,k]*trt[i,k,t] for i in products, k in products,t in periods) )

@objective(s, Min,  transslotcost + transperiodcost)

g = ModelGraph()
setsolver(g, GurobiSolver(MIPGap=gap))

plan = add_node(g)
setmodel(plan, m)

sched = add_node(g)
setmodel(sched, s)

@linkconstraint(g, [i in products, t in periods], plan[:Θ][i,t] == sched[:Θ][i,t])

if reverse
    add_edge(g,sched,plan)
else
    add_edge(g,plan,sched)
end

return g

end

g = plansched(gap=0.02)
