function runsimu(d::SCSData; verbose=true)
    for iter in 0:6
        verbose && println("START SIMULATION HOUR $iter")
        d.currentperiod = iter
        if iter > 0
            maintenance(d, verbose=verbose)
            operator(d, verbose=verbose)
        end
        if iter % 168 == 0
            verbose && println("START PLANNING PROCESS")
            demand_planner(d, verbose=verbose)
            logistics_planner(d, verbose=verbose)
            tactical_planner(d, verbose=verbose)
#            scheduler(d, verbose=verbose)
        end
    end
end
