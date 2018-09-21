mutable struct SCSData
    # Sets
    customers
    products
    materials
    plants
    units
    customersfor
    producttype
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
    graph
    inventory
    iterations
    # Time
    currentperiod
    ordernumber
end
