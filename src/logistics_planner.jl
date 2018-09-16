#="""
    Logistics Planner Agent

    Transforms incoming orders into deliveries

"""=#

@resumable function logistics_planner(d::SCSData)
    if isempty(d.forecast)
        initialize_orders!(d)
    else
        update_orders!(d)
    end
end


function initialize_orders!(d::SCSData, ts=d.currentperiod, te=ts+d.schedulinghorizon-1; verbose=false)
    for i in d.plants
        for p in d.products
            verbose && println("Generating orders for plant $i and product $p")
            iterend = Int(((te-ts+1)/7 - 1))
            verbose && println("ts = $ts, te = $te, Iter End = $iterend")
            forecast = sum(d.forecast[c,p,ts+7i] for c in d.customersfor[i] for i in 0:iterend)
            actualamount = forecast*rand(0.8:0.01:1.2)
            verbose && println("Forecast is $forecast, Actual amount is $actualamount")
            slots = rand(1:6) #TODO Number of slots needs to be a function of the length
            perm  = randperm(te-ts+1) .+ ts
            t = perm[1:slots]
            Q = [actualamount/slots*rand(0.8:0.01:1.2) for _ in 1:slots]
            Q[end] = max(forecast,actualamount) - sum(Q[1:end-1])
            for k in 1:slots
                verbose && println("Generating Delivery orders for plant $i and product $p for $(Q[k]) to be picked on period $(t[k])")
                push!(d.deliveries, Delivery(i,p,Q[k],t[k]))
            end
        end
    end
end

function update_orders!(d::SCSData; verbose=false)
    # TODO Perturb week 2 orders with a low probabiity
    # Maybe switch somes dates and/or amounts
    initialize_orders!(d, d.currentperiod+7, d.currentperiod+d.schedulinghorizon-1, verbose=verbose)
end
