using Base.Test
using SCSimulation


fcast_μ = Dict((:C1,:P1) => 100)
fcast_σ = Dict((:C1,:P1) => 20)
custfor = Dict(:M1 => [:C1])
d = SCSData([:C1], [:P1], [:M1], custfor, 84, 7, 0, 0, Delivery[], 14, Dict(),fcast_μ, fcast_σ, 0.5, 0.4, nothing,
Dict(), 1, 0)

initialize_forecast(d)
initialize_orders(d, verbose=true)

@test isa(d.deliveries[1], Delivery)

d.currentperiod = 7
update_orders(d, verbose=true)
