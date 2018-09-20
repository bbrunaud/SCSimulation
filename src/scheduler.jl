#="""
    Scheduler Agent

    Runs optimization model to determine optimal schedule

"""=#

@resumable function scheduler(d::SCSData)
    update_scheduling_models(d)
    for i in 2:length(getnodes(d.graph))
        JuMP.solve(getmodel(getnode(d.graph,i)))
    end
    post_production_orders(d)
end

function update_scheduling_models(d::SCSData; verbose=false)
    # Release inventory targets if planned and scheduling are done together
    if d.currentperiod % 672 == 0
        for i in d.plants
            n = 2
            m = getmodel(getnode(d.graph,n))
            invtgt = getindex(m, :invtgt)
            for k in keys(invtgt)
                setlowerbound(invtgt[k...], 0)
                setupperbound(invtgt[k...], Inf)
            end
            n += 1
        end
    # Update inventory targets
    else
        for i in d.plants
            n = 2
            m = getmodel(getnode(d.graph,n))
            invtgt = getindex(m, :invtgt)
            for k in keys(invtgt)
                JuMP.setlowerbound(invtgt[k...], 0)
                JuMP.setupperbound(invtgt[k...], Inf)
            end
            pm = getmodel(getnode(d.graph,1))
            pinv = getindex(pm, :inv)
            tmapr = map(reverse, pm.ext[:periodmap])
            for k in 1:Int(d.schedulinghorizon/168)
                planperiod = (d.currentperiod + 168*k)
                st = Int(k*168/d.schedulingdiscretization)
                if planperiod ∈ keys(tmapr)
                    pt = tmapr[planperiod]
                    verbose && println("pt = $pt,  st = $st, planperiod=$planperiod")
                    for p in d.products
                        JuMP.setlowerbound(invtgt[Symbol("Tk_",p),p,st], JuMP.getvalue(pinv[i,p,pt]))
                        JuMP.setupperbound(invtgt[Symbol("Tk_",p),p,st], JuMP.getvalue(pinv[i,p,pt]))
                    end
                end
            end
            n += 1
        end
    end
    # Add orders
    for i in d.plants
        n = 2
        m = getmodel(getnode(d.graph,n))
        D = getindex(m, :D)

        orders = @from row in d.deliveries begin
                 @where row.plant == i && row.status == :open && row.date > d.currentperiod
                 @select {row.product, row.date, row.amount}
                 @collect DataFrame
        end
        verbose && println("Setting all demands to zero")
        for k in keys(D)
            JuMP.setlowerbound(D[k...], 0)
            JuMP.setupperbound(D[k...], 0)
        end
        for k in 1:size(orders,1)
            modeltime = max(1, Int(ceil((orders[k,:date]-d.currentperiod)/d.schedulingdiscretization)-1))
            verbose && println("Setting order $(orders[k,:]) to $modeltime")
            JuMP.setlowerbound(D[orders[k,:product], modeltime], orders[k,:amount])
            JuMP.setupperbound(D[orders[k,:product], modeltime], orders[k,:amount])
        end
        n += 1
    end
end

function saveschedule(n::Scheduling.Network)
  df = DataFrame(Task=[], Unit=[], Start=[], Duration=[], Size=[])

  b = getindex(n.model, :b)
  bv = getvalue(b)

  for (i,j,t) in keys(bv)
    bv[i,j,t] > 1e-8 && push!(df, (j, i, t, n.processingtime[j], bv[i,j,t]))
  end

  sort!(df, cols=[:Start])
  n.schedule = df
  df
end


function post_production_orders(d::SCSData)
    for plant in d.plants
        n = 2
        m = getmodel(getnode(d.graph,n))
        net = getattribute(getnode(d.graph,n), :network)
        ct = getattribute(getnode(d.graph,n), :coefftable)
        b = getindex(net.model, :b)
        bv = JuMP.getvalue(b)

        for (i,j,t) in keys(bv)
            if bv[i,j,t] > 1e-8 && t <= 168/d.schedulingdiscretization
                # Increase order number
                d.ordernumber += 1
                # Save order general info
                starttime = d.schedulingdiscretization*t+d.currentperiod
                duration = d.schedulingdiscretization*net.processingtime[j]
                push!(d.orders, [d.ordernumber, plant, j, i, starttime, duration, bv[i,j,t], 0, 0, false, :planned])
                sort!(d.orders, cols=[:Start,:Task])
                # Save consumptions
                tb = @from row in ct begin
                     @where row.Task == j && row.Sense == :in
                     @select {row.Material, row.Coefficient}
                     @collect DataFrame
                 end
                for row in 1:size(tb,1)
                    push!(d.consumptions, [d.ordernumber, plant, j, i, tb[row,:Material], starttime,  bv[i,j,t]*tb[row,:Coefficient], :planned])
                end
                sort!(d.consumptions, cols=[:Time,:Task])
                # Save productions
                tbo = @from row in ct begin
                     @where row.Task == j && row.Sense == :out
                     @select {row.Material, row.Coefficient}
                     @collect DataFrame
                 end
                for row in 1:size(tbo,1)
                    push!(d.productions, [d.ordernumber, plant, j, i, tbo[row,:Material], starttime+duration,  bv[i,j,t]*tbo[row,:Coefficient], :planned])
                end
                sort!(d.productions, cols=[:Time,:Task])
            end
        end

        n += 1
    end
end
