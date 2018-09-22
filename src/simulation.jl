function runsimu(d::SCSData, hours=6; verbose=true)
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
#           else
		scheduler(d, verbose=verbose)
	    end
        end
    end
end
