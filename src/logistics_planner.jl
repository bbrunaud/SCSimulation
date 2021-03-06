#="""
    Logistics Planner Agent

    Transforms incoming orders into deliveries

"""=#

function logistics_planner(d::SCSData; verbose=true)
    if size(d.deliveries,1) == 0
        initialize_orders(d, verbose=verbose)
    else
        update_orders(d, verbose=verbose)
    end
end


function initialize_orders(d::SCSData, ts=d.currentperiod + 1, te=ts+335; verbose=false)
    for i in d.plants
        for p in d.products
            verbose && println("Generating orders for plant $i and product $p")
            verbose && println("ts = $ts, te = $te")
            iterend = Int(((te-ts+1)/d.planningdiscretization - 1))
            verbose && println("ts = $ts, te = $te, Iter End = $iterend")
	    for j in 1:iterend+1
		    forecast = sum(d.forecast[c,p,ts+d.planningdiscretization*j-1] for c in d.customersfor[i])
        	    actualamount = forecast*rand(0.8:0.01:1.2)
	            verbose && println("Forecast is $forecast, Actual amount is $actualamount")
        	    slots = rand(1:4) 
	            perm  = randperm(te-ts+1) .+ (ts-1)
        	    #verbose && println("Possible periods are $perm")
	            t = perm[1:slots]
        	    Q = [actualamount/slots*rand(0.8:0.01:1.2) for _ in 1:slots]
	            if d.producttype[p] == :MTS
        	        Q[end] = max(forecast,actualamount) - sum(Q[1:end-1])
	            end
        	    for k in 1:slots
                	verbose && println("Generating Delivery orders for plant $i and product $p for $(Q[k]) to be picked on period $(t[k])")
	                d.deliverynumber += 1
        	        push!(d.deliveries, [d.deliverynumber,i,p,Q[k],t[k], 0, t[k], false, :Open])
	            end
	    end
        end
    end
end

function update_orders(d::SCSData; verbose=false)
    # TODO Perturb week 2 orders with a low probabiity
    # Maybe switch somes dates and/or amounts
    initialize_orders(d, d.currentperiod+169, d.currentperiod+336, verbose=verbose)
end
