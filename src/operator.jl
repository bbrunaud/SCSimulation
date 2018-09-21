function operator(d::SCSData; verbose=true)
    # Get current inventory
    inventory = Dict((i,p) => d.inventory[i,p,d.currentperiod-1] for i in d.plants for p in d.materials if (i,p,d.currentperiod-1) in keys(d.inventory))

    # Offload Units
    println("Checking for finished tasks")
    finished = @from row in d.productions begin
               @where row.Time == d.currentperiod
               @select {row.Order, row.Plant, row.Task, row.Unit, row.Material, row.Amount, row.Status}
               @collect DataFrame
           end
    verbose && println("Offloading tasks: $finished")
    for k in 1:size(finished, 1)
        ordernum = finished[k,:Order]
        iin = findin(ordernum, d.orders[:Order])
        d.orders[iin,:Status] = :Finished
        d.unitstatus[finished[k,:Plant], finished[k,:Unit]] = :Available
        inventory[finished[k,:Plant], finished[k,:Material]] += finished[k,:Amount]
    end

    # Load Units
    println("Checking for starting tasks")
    starting = @from row in d.consumptions begin
               @where row.Time == d.currentperiod
               @select {row.Order, row.Plant, row.Task, row.Unit, row.Material, row.Amount, row.Status}
               @collect DataFrame
           end
    verbose && println("Starting tasks: $starting")
    for k in 1:size(starting, 1)
        ordernum = starting[k,:Order]
        iin = indexin([ordernum], d.orders[:Order])[1]
        d.orders[iin,:Status] = :Running
        verbose && println("Order $ordernum set to running, $iin")
        d.unitstatus[starting[k,:Plant], starting[k,:Unit]] = :Busy
        inventory[starting[k,:Plant], starting[k,:Material]] -= starting[k,:Amount]
    end

    #= Serve Deliveries
    println("Serving Delivieries")
    deliveries = @from row in d.deliveries begin
                 @where row.Actual_Date == d.currentperiod
                 @collect {row.Plant, row.Product, row.Amount, }
    =#

    # Pass inventory to next period
    println("Passing Inventory from period $(d.currentperiod -1) to period $(d.currentperiod)")
    for i in d.plants
        for p in d.materials
            d.inventory[i,p,d.currentperiod] = inventory[i,p]
        end
    end
end

function maintenance(d::SCSData; verbose=false)
    t = d.currentperiod
    verbose && println("Checking for repair events for $t")
    # Start Repairs
    fails = @from row in d.maintenance begin
            @where row.Start == t
            @select {row.Plant, row.Unit, row.End}
            @collect DataFrame
        end
    verbose && println("Today's fails are $fails")
    for k in 1:size(fails,1)
        if d.unitstatus[fails[k,:Plant],fails[k,:Unit]] == :Available
            d.unitstatus[fails[k,:Plant],fails[k,:Unit]] = :Repair
        else
            verbose && println("Unit $(fails[k,:Unit]) busy, reparation postponed")
            fails[k,:Start] += 1
            fails[k,:End] += 1
        end
    end
    # End Repairs
    repairs = @from row in d.maintenance begin
            @where row.End == t
            @select {row.Plant, row.Unit, row.Start, row.End}
            @collect DataFrame
        end
    verbose && println("Today's fails are $repairs")
    for k in 1:size(repairs,1)
        d.unitstatus[repairs[k,:Plant],repairs[k,:Unit]] = :Available
    end
end
