function operator(d::SCSData; verbose=true)
    # Pass Inventory
    passinventory(d, verbose=verbose)

    # Offload Units
    unload(d, verbose=verbose)

    # Load Units

    verbose && size(starting,1) > 0 && println("Starting tasks: $starting")

    # Actual Production
    if size(starting, 1) > 0
        if unitavailable && inventoryavailable
            ordernum = starting[1,:Order]
            iin = indexin([ordernum], d.orders[:Order])[1]
            d.orders[iin,:Status] = :Running
            verbose && println("Order $ordernum set to running, $iin")
            for k in 1:size(starting, 1)
                d.unitstatus[starting[k,:Plant], starting[k,:Unit]] = :Busy
                inventory[starting[k,:Plant], starting[k,:Material]] -= starting[k,:Amount]
            end
        else

        end
    end

    #= Serve Deliveries
    println("Serving Delivieries")
    deliveries = @from row in d.deliveries begin
                 @where row.Actual_Date == d.currentperiod
                 @collect {row.Plant, row.Product, row.Amount, }
    =#


end

function passinventory(d::SCSData; verbose=false)
    # Pass inventory to next period
    verbose && println("Passing Inventory from period $(d.currentperiod -1) to period $(d.currentperiod)")
    for i in d.plants
        for p in d.materials
            d.inventory[i,p,d.currentperiod] = d.inventory[i,p,d.currentperiod-1]
        end
    end
end


function unload(d::SCSData; verbose=true)
    verbose && println("Checking for finished tasks")
    finished = @from row in d.productions begin
               @where row.ActualTime == d.currentperiod
               @select {row.Number, row.Order, row.Plant, row.Task, row.Unit, row.Material, row.Amount}
               @collect DataFrame
           end
    if size(finished, 1) == 0
        verbose && println("No units to unload")
        return true
    end
    verbose && println("Offloading tasks: $finished")
    for k in 1:size(finished, 1)
        ordernum = finished[k,:Order]
        iin = findin(ordernum, d.orders[:Order])
        d.orders[iin,:Status] = :Finished
        d.unitstatus[finished[k,:Plant], finished[k,:Unit]] = :Available
        d.inventory[finished[k,:Plant], finished[k,:Material], d.currentperiod] += finished[k,:Amount]
    end
end


function executeproduction(d::SCSData; verbose=false)
    verbose && println("Checking for starting tasks")
    starting = @from row in d.orders begin
               @where row.ActualStart == d.currentperiod
               @select {row.Order, row.Plant, row.Task, row.Unit, row.Material, row.Amount}
               @collect DataFrame
           end
    if size(starting, 1) == 0
        verbose && println("No orders for today")
        return true
    else
        verbose && println("Today's orders are $starting")
    end

    for order in starting[:Order]
        if orderpossible(d, order, verbose=verbose)
            executeorder(d, order, verbose=verbose)
        else
            postponeorder(d, order, verbose=verbose)
        end
    end
end


function orderpossible(d::SCSData, order; verbose=false)
    # Check if task is possible
    # Check if unit is available
    orderinfo = @from row in d.orders begin
                @where row.Order == order
                @select {row.Order, row.Plant, row.Unit}
                @collect DataFrame
            end
    if d.unitstatus[orderinfo[1,:Plant], orderinfo[1,:Unit]] != :Available
        verbose && println("Unit $(orderinfo[1,:Unit]) unavailable")
        return false
    end
    # Check for enough inventory
    inventoryavailable = true
    consumptions = @from row in d.consumptions begin
                    @where row.Order == order
                    @select {row.Plant, row.Material, row.Amount}
                    @collect DataFrame
            end
    for k in 1:size(consumptions, 1)
        if inventory[consumptions[k,:Plant], consumptions[k,:Material]] < consumptions[k,:Amount]
            verbose && println("Not enough inventory of material $(consumptions[k,:Material])")
            return false
        end
    end
    verbose && println("Order $order feasible")
    return true
end


function postponeorder(d::SCSData, ordernum; verbose=false)
    verbose && println("Postponing Order $ordernum")
    iin = indexin([ordernum], d.orders[:Order])[1]
    d.orders[iin,:Start] += 1
    for k in 1:size(starting, 1)
        cnum = starting[k,:Number]
        cidx = indexin([cnum], d.consumptions[:Number])[1]
        d.consumptions[cidx, :ActualTime] += 1
    end
    prods = @from row in d.productions begin
            @where row.Order == ordernum
            @select {row.Number}
            @collect DataFrame
        end
    for k in 1:size(prods,1)
        pidx = indexin([prods[k,:Number]], d.productions[:Number])[1]
        d.productions[pidx, :ActualTime] += 1
    end
end


function maintenance(d::SCSData; verbose=false)
    verbose && println("Checking for repair events for $(d.currentperiod)")
    # Start Repairs
    fails = @from row in d.maintenance begin
            @where row.Start == d.currentperiod
            @select {row.Plant, row.Unit, row.End}
            @collect DataFrame
        end
    if size(fails,1) == 0
        return true
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
            @where row.End == d.currentperiod
            @select {row.Plant, row.Unit, row.Start, row.End}
            @collect DataFrame
        end
    verbose && println("Today's fails are $repairs")
    for k in 1:size(repairs,1)
        d.unitstatus[repairs[k,:Plant],repairs[k,:Unit]] = :Available
    end
end
