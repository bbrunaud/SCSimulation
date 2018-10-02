mutable struct SCSData
    # Sets
    customers
    products
    materials
    plants
    units
    customersfor
    producttype
    price
    # Planning
    planninghorizon
    planningdiscretization
    planstartperiod
    planendperiod
    # Logistics
    deliveries
    orders
    consumptions
    productions
    maintenance
    unitstatus
    ordermap
    # Scheduling
    schedulinghorizon
    schedulingdiscretization
    # Forecast
    forecast
    forecast_μ
    forecast_σ
    forecastvariation
    forecastvariationpercent
    # Models
    graphfunction
    graph
    inventory
    iterations
    # Control
    gaps
    currentperiod
    ordernumber
    deliverynumber
    consumptionnumber
    productionnumber
    profit
end

mutable struct SimuRun
	name
	description
	seed
	hours
	clocktime
	orders
	deliveries
	gaps
	profit
	averagegap
	averageinventory
	backlogamount
	backlognumber
	totaldelivered
end

function SimuRun(name,description,seed,hours)
	return SimuRun(name,description,seed,hours,0,nothing,nothing,Float64[],0,0,0,0,0,0)
end
