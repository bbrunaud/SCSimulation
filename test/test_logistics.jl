using Base.Test
using SCSimulation
using DataFrames

fcast_μ = Dict((:C1,:P1) => 100)
fcast_σ = Dict((:C1,:P1) => 20)
custfor = Dict(:M1 => [:C1])
ptype = Dict(:P1 => :MTS)

d = SCSData([:C1],
            [:P1],
            [:M1],
            custfor,
            ptype,
            1344,
            168,
            0,
            0,
            DataFrame(plant=[],product=[],amount=[],date=[], delivered=[], actual_date=[], status=[]),
            336,
            4,
            Dict(),
            fcast_μ,
            fcast_σ,
            0.5,
            0.4,
            nothing,
            Dict(),
            1,
            0)

initialize_forecast(d)
initialize_orders(d, verbose=true)

@test size(d.deliveries,1) > 0

d.currentperiod = 168
update_orders(d, verbose=true)
