#="""
    Scheduler Agent

    Runs optimization model to determine optimal schedule

"""=#

@resumable function scheduler(d::SCSData)
    update_scheduling_models(d)
    for i in 2:length(getnodes(d.graph))
        JuMP.solve(getmodel(getnode(d.graph,i))
    end
    post_production_orders(d)
end

function update_scheduling_models(d::SCSData; verbose=false)
    # Release inventory targets if planned and scheduling are done together
    if d.currentperiod % 672 == 0
    end
    # Update inventory targets
    for i in d.plants
        n = 2
        m = getmodel(getnode(d.graph,n))
        invtgt = getindex(m, :invtgt)
        sm = getmodel(getnode(d.graph,1))
        pinv = getindex(m, :inv)
        for k in 1:2
            pt = ((d.currentperiod + 168*k) / 168) % 4
            st = k*d.schedulingdiscretization
            verbose && println("pt = $pt,  st = $st")
            JuMP.fix(invtgt[p,st], getvalue(pinv[p,pt]))
        end
        n += 1
    end
end

function post_production_orders(d::SCSData)
end
