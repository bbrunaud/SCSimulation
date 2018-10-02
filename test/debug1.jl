using Revise
using DataFrames

include("test_simulation.jl")

d.iterations = Inf
demand_planner(d)
logistics_planner(d)

update_planning_model(d)
update_scheduling_models(d)

#=update_monolith(d)
mf = getattribute(d.graph,:monolith)
mf.solver = GurobiSolver(MIPGap=0.01)
solve(mf)
monolith_to_graph(mf,d.graph)
=#
Plasmo.setsolver(d.graph, GurobiSolver(MIPGap=0.01))
solve(d.graph)

m1 = getmodel(getnode(d.graph,1))
m2 = getmodel(getnode(d.graph,2))

net = getattribute(getnode(d.graph,2),:network)


function ps()
    println("FLOWS")
    f = DataFrame(Plant=[],Customer=[],Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m1[:f])
        val = JuMP.getvalue(m1[:f][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m1[:f][k...])
            ub = JuMP.getupperbound(m1[:f][k...])
            push!(f,vcat(k...,[lb,val,ub]))
        end
    end
    println(f)

    println("UNSATISFIED DEMAND")
    ud = DataFrame(Customer=[],Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m1[:ud])
        val = JuMP.getvalue(m1[:ud][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m1[:ud][k...])
            ub = JuMP.getupperbound(m1[:ud][k...])
            push!(ud,vcat(k...,[lb,val,ub]))
        end
    end
    println(ud)

    println("DEMAND")
    D = DataFrame(Customer=[],Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m1[:D])
        val = JuMP.getvalue(m1[:D][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m1[:D][k...])
            ub = JuMP.getupperbound(m1[:D][k...])
            push!(D,vcat(k...,[lb,val,ub]))
        end
    end
    println(D)

    println("PRODUCTION PLAN")
    x = DataFrame(Plant=[],Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m1[:x])
        val = JuMP.getvalue(m1[:x][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m1[:x][k...])
            ub = JuMP.getupperbound(m1[:x][k...])
            push!(x,vcat(k...,[lb,val,ub]))
        end
    end
    println(x)

    println("SCHEDULE")
    sched = Scheduling.savescheduleSTN!(net)
    println(sched)

    println("DELIVERIES")
    println(d.deliveries)

    println("BACKLOG")
    bl = DataFrame(Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m2[:bl])
        val = JuMP.getvalue(m2[:bl][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m2[:bl][k...])
            ub = JuMP.getupperbound(m2[:bl][k...])
            push!(bl,vcat(k...,[lb,val,ub]))
        end
    end
    println(bl)

    println("SERVINGS")
    dv = DataFrame(Product=[],Time2=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m2[:d])
        val = JuMP.getvalue(m2[:d][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m2[:d][k...])
            ub = JuMP.getupperbound(m2[:d][k...])
            push!(dv,vcat(k...,[lb,val,ub]))
        end
    end
    println(dv)

    println("REMOVED DEMAND")
    rd = DataFrame(Product=[],Time=[],LB=[],Value=[],UB=[])
    for k in keys(m2[:rd])
        val = JuMP.getvalue(m2[:rd][k...])
        if val > 1e-8
            lb = JuMP.getlowerbound(m2[:rd][k...])
            ub = JuMP.getupperbound(m2[:rd][k...])
            push!(rd,vcat(k...,[lb,val,ub]))
        end
    end
    println(rd)
end

ps()
