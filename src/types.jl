mutable struct SCSData
    # Sets
    customers
    products
    plants
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
