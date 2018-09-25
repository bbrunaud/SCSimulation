#="""
    Scheduler Agent

    Runs optimization model to determine optimal schedule

"""=#

function scheduler(d::SCSData; verbose=verbose)
    update_scheduling_models(d, verbose=verbose)
    for i in 2:length(getnodes(d.graph))
        JuMP.solve(getmodel(getnode(d.graph,i)))
    end
    post_production_orders(d, verbose=verbose)
end

function update_scheduling_models(d::SCSData; verbose=false)
    # Release inventory targets if planned and scheduling are done together
    if d.currentperiod % 672 == 0
        for i in d.plants
            n = 2
            m = getmodel(getnode(d.graph,n))
            invtgt = getindex(m, :invtgt)
            prodtgt = getindex(m, :prodtgt)
            for k in keys(invtgt)
                JuMP.setlowerbound(invtgt[k...], 0)
                JuMP.setupperbound(invtgt[k...], Inf)
            end
            for k in keys(prodtgt)
                JuMP.setlowerbound(prodtgt[k...], 0)
                JuMP.setupperbound(prodtgt[k...], Inf)
            end
            n += 1
        end
    # Update inventory targets
    else
        for i in d.plants
            n = 2
            m = getmodel(getnode(d.graph,n))
            invtgt = getindex(m, :invtgt)
            prodtgt = getindex(m, :prodtgt)
            for k in keys(invtgt)
                JuMP.setlowerbound(invtgt[k...], 0)
                JuMP.setupperbound(invtgt[k...], Inf)
            end
            for k in keys(prodtgt)
                JuMP.setlowerbound(prodtgt[k...], 0)
                JuMP.setupperbound(prodtgt[k...], Inf)
            end
            pm = getmodel(getnode(d.graph,1))
            pinv = getindex(pm, :inv)
            x = getindex(pm, :x)
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
                        JuMP.setlowerbound(prodtgt[p,Int(st*d.schedulingdiscretization/168)], JuMP.getvalue(x[i,p,pt]))
                        JuMP.setupperbound(prodtgt[p,Int(st*d.schedulingdiscretization/168)], JuMP.getvalue(x[i,p,pt]))
                    end
                end
            end
            n += 1
        end
    end
    # Update initial inventory
    for i in d.plants
	n = 2
        m = getmodel(getnode(d.graph,n))
        inv = getindex(m, :inv)
	for p in d.materials
	    setlowerbound(inv[Symbol("Tk_",p),p,-1],d.inventory[i,p,d.currentperiod])
	    setupperbound(inv[Symbol("Tk_",p),p,-1],d.inventory[i,p,d.currentperiod])
	end
	n += 1
    end
    # Add orders
    for i in d.plants
        n = 2
        m = getmodel(getnode(d.graph,n))
        D = getindex(m, :D)

        orders = @from row in d.deliveries begin
                 @where row.Plant == i && row.Status == :Open && row.Date > d.currentperiod
                 @select {row.Product, row.Date, row.Amount}
                 @collect DataFrame
        end
        verbose && println("Setting all demands to zero")
        for k in keys(D)
            JuMP.setlowerbound(D[k...], 0)
            JuMP.setupperbound(D[k...], 0)
        end
        for k in 1:size(orders,1)
            modeltime = max(1, Int(ceil((orders[k,:Date]-d.currentperiod)/d.schedulingdiscretization)-1))
            verbose && println("Setting order $(orders[k,:]) to $modeltime")
            JuMP.setlowerbound(D[orders[k,:Product], modeltime], orders[k,:Amount])
            JuMP.setupperbound(D[orders[k,:Product], modeltime], orders[k,:Amount])
        end
        n += 1
    end
    # Update unavailable equipment
    for i in d.plants
		n = 2
		m = getmodel(getnode(d.graph,n))
		net = getattribute(getnode(d.graph,n),:network)
		su = getindex(m, :su)
		for k in keys(su)
			setupperbound(su[k...], 1)
		end
		for unit in net.units
			if d.unitstatus[i,unit] == :Repair
				rtdf = @from row in d.maintenance begin
					   @where row.Plant == i && row.Unit == unit
					   @select {row.End}
					   @collect DataFrame
			   end
			   verbose && println("Making Unit $unit Unavailable in the scheduling model")
			   repairtime = rtdf[1,1]
			   repairperiod = Int(ceil((repairtime - d.currentperiod - 1)/d.schedulingdiscretization))
			   for t in 1:repairperiod
				   for j in net.tasks[unit]
			   			setupperbound(su[unit,j,t], 0)
				   end
		 	   end
		    	end
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


function post_production_orders(d::SCSData; verbose=true)
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
                push!(d.orders, [d.ordernumber, plant, j, i, starttime, duration, starttime+duration, bv[i,j,t], starttime, duration, starttime+duration, false, :Planned])
                sort!(d.orders, cols=[:Start,:Task])
                # Save consumptions
                tb = @from row in ct begin
                     @where row.Task == j && row.Sense == :in
                     @select {row.Material, row.Coefficient}
                     @collect DataFrame
                 end
                for row in 1:size(tb,1)
                    d.consumptionnumber += 1
                    push!(d.consumptions, [d.consumptionnumber, d.ordernumber, plant, j, i, tb[row,:Material],  bv[i,j,t]*tb[row,:Coefficient]])
                end
                sort!(d.consumptions, cols=[:Number,:Task])
                # Save productions
                tbo = @from row in ct begin
                     @where row.Task == j && row.Sense == :out
                     @select {row.Material, row.Coefficient}
                     @collect DataFrame
                 end
                for row in 1:size(tbo,1)
                    d.productionnumber += 1
                    push!(d.productions, [d.productionnumber, d.ordernumber, plant, j, i, tbo[row,:Material], bv[i,j,t]*tbo[row,:Coefficient], bv[i,j,t]*tbo[row,:Coefficient]])
                end
                sort!(d.productions, cols=[:Number,:Task])
            end
        end

        n += 1
    end
end
