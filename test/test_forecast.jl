using Base.Test
using SCSimulation
using Gaston

fcast_μ = Dict((:C1,:P1) => 100)
fcast_σ = Dict((:C1,:P1) => 20)
custfor = Dict(:M1 => [:C1])
ptype = Dict(:P1 => :MTS)

d = SCSData([:C1],
            [:P1],
            [:M1],
            custfor,
            ptype,
            6,
            1,
            0,
            0,
            nothing,
            0,
            0,
            Dict(),
            fcast_μ,
            fcast_σ,
            0.5,
            0.4,
            nothing,
            Dict(),
            1,
            0)

initialize_forecast(d,verbose=true)
@test length(d.forecast) == 6
@test d.planstartperiod == 1
@test d.planendperiod == 6

fcast = [d.forecast[:C1,:P1,i] for i in 1:6]
update_forecast(d,verbose=true)
fcast2 = [d.forecast[:C1,:P1,i] for i in 1:6]
plot(fcast)
plot!(fcast2, color="green")

d.currentperiod = 4
update_forecast(d,verbose=true)
@test d.planstartperiod == 5
@test d.planendperiod == 10
fcast3 = [d.forecast[:C1,:P1,i] for i in 1:10]
plot!(fcast3, color="red")
