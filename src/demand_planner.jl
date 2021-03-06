#="""
    Forecast Planner Agent

    Estimates the demand forecast for each product at each customer location
    during the planning horizon. Updates an existing forecast.

"""=#


function demand_planner(d::SCSData; verbose=true)
    verbose && "START demand planner"
    if isempty(d.forecast)
        verbose && "Forecast is empty, generating a new one"
        initialize_forecast(d, verbose=verbose)
    else
        update_forecast(d, verbose=verbose)
    end
end

function initialize_forecast(d::SCSData, ts=d.currentperiod+d.planningdiscretization, te=ts + d.planninghorizon - 1; verbose=false)
    verbose && println("Initializing Forecast with ts = $ts, te=$te")
    d.planstartperiod = ts
    H = d.planninghorizon
    d.planendperiod = te
    T = d.planningdiscretization
    for c in d.customers
        for p in d.products
            dem = Normal(d.forecast_μ[c,p], d.forecast_σ[c,p])
            for t in ts:T:te
                verbose && println("Setting forecast for customer $c, product $p, period $t")
                d.forecast[c,p,t] = rand(dem)
            end
        end
    end
end

function update_forecast(d::SCSData; verbose=false)
    ts = d.currentperiod + 168
    H = d.planninghorizon
    T = d.planningdiscretization
    for t in ts:T:d.planendperiod
        for c in d.customers
            for p in d.products
                if rand() < d.forecastvariation
                    d.forecast[c,p,t]*=rand(1-d.forecastvariationpercent*t/d.planendperiod:0.01:1+d.forecastvariationpercent*t/d.planendperiod)
                end
            end
        end
    end
    if d.planendperiod+168 <= ts+H-1
        verbose && println("New forecast starting at t = $(d.planendperiod+1)")
        initialize_forecast(d, d.planendperiod+1, ts+H-1, verbose=verbose)
    end
    d.planstartperiod = ts
    d.planendperiod = ts + H - 1
end
