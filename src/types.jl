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
    # Scheduling
    schedulinghorizon
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
end

mutable struct SCSim
    sim
    data
end

mutable struct Delivery
    plant
    product
    amount
    date
end
