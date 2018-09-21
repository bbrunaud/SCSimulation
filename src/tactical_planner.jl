#="""
    Tactical Planner Agent

    Runs optimization model to determine mid-term
    together with sort term scheduling

"""=#

function tactical_planner(d::SCSData; verbose=true)
    update_planning_model(d)
    update_scheduling_models(d)
    if d.iterations < Inf
        bendersolve(d.graph, max_iterations=d.iterations)
    else
        JuMP.solve(getattribute(d.graph,:monolith))
        monolith_to_graph(d)
    end
    post_production_orders(d)
end


function update_planning_model(d)
    # Assuming the first node is the planning model
    node = getnode(d.graph,1)
    m = getmodel(node)
    # Update period map
    tmap = m.ext[:periodmap]
    periods = d.planningdiscretization:d.planningdiscretization:d.planninghorizon
    for (t,T) in enumerate(periods)
        tmap[t] = T
    end
    # Update initial inventory
    inv = getindex(m, :inv)
    for i in d.plants
        for p in d.products
             JuMP.fix(inv[i,p,0], d.inventory[i,p,d.currentperiod])
             setcategory(inv[i,p,0], :Cont)
         end
    end
    # Update demand
    D = getindex(m, :D)
    for c in d.customers
        for p in d.products
            for t in 1:m.ext[:numperiods]
                JuMP.fix(D[c,p,t], d.forecast[c,p,tmap[t]])
                setcategory(D[c,p,t], :Cont)
            end
        end
    end
end

"""
Pass solution from monolith model to individual models in the graph
"""
function monolith_to_graph(model::JuMP.Model, graph::ModelGraph)
    k = 1
    for i in 1:length(getnodes(graph))
        m = getmodel(getnode(graph,i))
        m.colVal = model.colVal[k:k+m.numCols-1]
        k = m.numCols + 1
    end
end

monolith_to_graph(d::SCSData) = monolith_to_graph(getattribute(d.graph,:monolith), d.graph)
