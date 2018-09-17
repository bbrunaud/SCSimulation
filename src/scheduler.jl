#="""
    Scheduler Agent

    Runs optimization model to determine optimal schedule

"""=#

@resumable function scheduler(d::SCSData)
    update_scheduling_models(d)
    JuMP.solve(getattribute(d.graph,:monolith))
    post_production_orders(d)
end

function update_scheduling_models(d::SCSData)
end

function post_production_orders(d::SCSData)
end
