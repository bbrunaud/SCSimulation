function runsimu(d::SCSData, hours=6; seed=12345, name="", description="", verbose=true)
	t = tic()
	srand(seed)
	r = SimuRun(name,description,seed,hours)
    for h in 0:hours
        verbose && println("START SIMULATION HOUR $h")
        d.currentperiod = h
        if h > 0
            maintenance(d, verbose=verbose)
            operator(d, verbose=verbose)
        end
        if h % 168 == 0
            verbose && println("START PLANNING PROCESS")
            demand_planner(d, verbose=verbose)
            logistics_planner(d, verbose=verbose)
            if h % 672 == 0
	    	tactical_planner(d, verbose=verbose)
            else
		scheduler(d, verbose=verbose)
	    end
        end
    end
    r.name = name
    r.description = description
    r.seed = seed
    r.hours = hours
    r.deliveries = d.deliveries
    r.orders = d.orders
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

    backlogamount = sum(partial[:Amount] - partial[:Delivered])
    deliveredamount = sum(r.deliveries[:Amount])

    r.backlogamount = backlogamount / deliveredamount
    r.backlognumber = numberofbacklogs / numberofdeliveries
    r.totaldelivered = deliveredamount
    return r
end
