using JuMP
using Gurobi

include("P5T24data3.jl")

# TODO incluir todos los parametros necesarios para saber cuando es un planer y cuando es un scheduler
#function monolith(D,R,INVI,Winit,N_products,N_periods,x_planner,bool_scheduler)
function monolith(D,R,INVI,Winit,N_products,N_periods)
    products = 1:N_products
    periods = 1:N_periods
    slots = 1:length(products)

    m = Model(solver=GurobiSolver(MIPGap=0,OutputFlag=0))

    @variable(m, w[i in products, l in slots, t in periods], Bin)
    @variable(m, Θl[i in products, l in slots, t in periods] >= 0) # Should be positive
    @variable(m, xl[i in products, l in slots, t in periods] >= 0)
    @variable(m, Θ[i in products, t in periods] >= 0)
    @variable(m, x[i in products, t in periods] >= 0)
    @variable(m, z[i in products, k in products, l in slots, t in periods] >= 0)
    @variable(m, te[l in slots, t in periods] >= 0)
    @variable(m, ts[l in slots, t in periods] >= 0)
    @variable(m, trt[i in products, k in products, t in periods] >= 0)
    @variable(m, trt0[i in products, k in products] >= 0)
    @variable(m, inv[i in products, t in periods] >= 0)
    @variable(m, invo[i in products, t in periods] >= 0)
    @variable(m, s[i in products, t in periods], lowerbound=D[i,t])
    @variable(m, area[i in products, t in periods] >= 0)

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
    @constraint(m, eq2[l in slots, t in periods], sum(w[i,l,t] for i in products) == 1 )
    @constraint(m, eq3a[i in products, l in slots, t in periods], Θl[i,l,t] <= H[t]*w[i,l,t])
    @constraint(m, eq3b[i in products, t in periods], Θ[i,t] == sum(Θl[i,l,t] for l in slots))
    @constraint(m, eq4a[i in products, l in slots, t in periods], xl[i,l,t] == R[i]*Θl[i,l,t])
    @constraint(m, eq4b[i in products, t in periods], x[i,t] == sum(xl[i,l,t] for l in slots))

    # C) Transitions
    @constraint(m, eq5[i in products, k in products, l in slots, t in periods;l<slots[end] && i!=k], z[i,k,l,t] >= w[i,l,t] + w[k,l+1,t] - 1)

    # D) Timing Relations
    @constraint(m, eq6[l in slots, t in periods], te[l,t] == ts[l,t] + sum(Θl[i,l,t] for i in products) + sum(τ[i,k]*z[i,k,l,t] for i in products, k in products) )
    @constraint(m, eq7[i in products, k in products, t in periods; t<periods[end] && i!=k], trt[i,k,t] >= w[i,slots[end],t] + w[k,slots[1],t+1] - 1)
    @constraint(m, eq7b[i in products, k in products; i!=k], trt0[i,k] >= Winit[i] + w[k,slots[1],1] - 1)
    @constraint(m, eq8[t in periods;t<periods[end]], te[slots[end],t] + sum(τ[i,k]*trt[i,k,t] for i in products, k in products) == ts[slots[1],t+1])
    @constraint(m, eq8b, sum(τ[i,k]*trt0[i,k] for i in products, k in products) == ts[slots[1],1])
    @constraint(m, eq9[l in slots, t in periods;l<slots[end]], te[l,t] == ts[l+1,t])
    @constraint(m, eq10[t in periods], te[slots[end], t] <= HT[t])

    # E) Inventory
    @constraint(m, eq11a[i in products], inv[i,1] == INVI[i] + x[i,1])
    @constraint(m, eq11b[i in products, t in periods;t>1], inv[i,t] == invo[i,t-1] + x[i,t])
    @constraint(m, eq12[i in products, t in periods], invo[i,t] == inv[i,t] - s[i,t])
    @constraint(m, eq13[i in products, t in periods;t>1], area[i,t] >= (invo[i,t-1] + x[i,t])*H[t])
    @constraint(m, eq13b[i in products], area[i,1] >= (INVI[i] + x[i,1])*H[1])

    # F) Demand
    #@constraint(m, eq15[i in products, t in periods], s[i,t] >= D[i,t])
    # No need, specified as bound


    # A) Objective Function
    @expression(m, sales, sum(P[i]*s[i,t] for i in products, t in periods))
    @expression(m, invcost, CInv*sum(area[i,t] for t in periods, i in products) )
    @expression(m, opercost, sum(COper[i]*x[i,t] for i in products, t in periods) )
    @expression(m, transslotcost, sum(CTrans[i,k]*z[i,k,l,t] for i in products, k in products, l in slots, t in periods) )
    @expression(m, transperiodcost, sum(CTrans[i,k]*trt[i,k,t] for i in products, k in products,t in periods) )
    @expression(m, inittransperiodcost, sum(CTrans[i,k]*trt0[i,k] for i in products, k in products) )

    #if bool_scheduler == true
    #    @variable(m, slack_p[i in products] >= 0)
    #    @variable(m, slack_n[i in products] >= 0)
    #    @constraint(m, eq_pen[i in products], x[i,1]-x_planner[i] >= slack_p[i]-slack_n[i])
    #    @expression(m, penalization, 1e5*sum(slack_p[i]+slack_n[i] for i in products) )
    #    @objective(m, Max, sales - invcost - opercost - transslotcost - transperiodcost - inittransperiodcost - penalization)
    #else
        @objective(m, Max, sales - invcost - opercost - transslotcost - transperiodcost - inittransperiodcost)
    #end

    return m
end

#=
Planner variables:
Θ = production time of product i in period t
x = amount produced of product i in period t
inv = inventory level of product i at the end of time period t
invo = final inventory of product i at time t after demands are satisfied
s = sales of product i in period t
area = area below the inventory time graph for product i at period t

Scheduler variables:
Θ = production time of product i in period t
x = amount produced of product i in period t

w = binary variable to denote if product i is assigned to slot l of period t
Θl = production time of product i in slot l of period t
xl = amount produced of product i in slot l of period t
z = to denote if product i is followed by product k in slot l of period t
te = end time of slot l in period t
ts = start time of slot l in period t
trt = to denote if product i is followed by product k at the end of period t
=#
