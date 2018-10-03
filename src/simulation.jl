function runsimu(d::SCSData, hours=6; seed=12345, name="", description="", verbose=true)
	println("#### BEGIN SIMULATION ####")
	t = tic()
	srand(seed)
	r = SimuRun(name,description,seed,hours)
    for h in 0:hours
        d.currentperiod = h
        if h > 0
            maintenance(d, verbose=verbose)
            operator(d, verbose=verbose)
        end
        if h % 168 == 0	  
		println("START SIMULATION WEEK $(Int(h/168+1))")
            demand_planner(d, verbose=verbose)
            logistics_planner(d, verbose=verbose)
            if h % 672 == 0
		println("PLANNING . . .")
	    	tactical_planner(d, verbose=verbose)
            else
		println("SCHEDULING . . .")
		scheduler(d, verbose=verbose)
	    end
        end
    end
    println("SAVING DATA")
    r.name = name
    r.description = description
    r.seed = seed
    r.hours = hours
    r.deliveries = d.deliveries
    r.orders = d.orders
    r.inventory = d.inventory
    r.gaps = d.gaps
    r.clocktime = toc()
    r.profit = d.profit
    r.averagegap = mean(r.gaps)
    r.averageinventory = mean([mean(d.inventory[i,p,t] for t in 1:r.hours) for i in d.plants for p in d.products])

    partial = @from i in r.deliveries begin
              @where i.Status == :Partial
              @select {i.Amount, i.Delivered}
              @collect DataFrame
          end
    numberofbacklogs = size(partial,1)
    numberofdeliveries = size(r.deliveries,1)

    if size(partial,1) > 0
	    backlogamount = sum(partial[:Amount] - partial[:Delivered])
    else
	    backlogamount = 0
    end
    deliveredamount = sum(r.deliveries[:Amount])
    
    r.deliveredperhour = deliveredamount/r.hours
    r.backlogamount = backlogamount / deliveredamount
    r.backlognumber = numberofbacklogs / numberofdeliveries
    r.totaldelivered = deliveredamount
    r.utilization = sum(r.orders[k,:ActualDuration] for k in 1:size(r.orders,1) if r.orders[k,:Status] == :Finished)/length(d.units[:M1])/r.hours
    return r
end
