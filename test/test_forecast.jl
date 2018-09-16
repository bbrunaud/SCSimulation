using Base.Test
using SCSimulation
using Gaston

fcast_μ = Dict((:C1,:P1) => 100)
fcast_σ = Dict((:C1,:P1) => 20)
custfor = Dict(:M1 => [:C1])
d = SCSData([:C1], [:P1], [:M1], custfor, 6, 1, 0, 0, Delivery[], 0, Dict(),fcast_μ, fcast_σ, 0.5, 0.4, 1)

initialize_forecast!(d,verbose=true)
@test length(d.forecast) == 6
@test d.planstartperiod == 1
@test d.planendperiod == 6

fcast = [d.forecast[:C1,:P1,i] for i in 1:6]
update_forecast!(d,verbose=true)
fcast2 = [d.forecast[:C1,:P1,i] for i in 1:6]
plot(fcast)
plot!(fcast2, color="green")

d.currentperiod = 4
update_forecast!(d,verbose=true)
@test d.planstartperiod == 4
@test d.planendperiod == 9
fcast3 = [d.forecast[:C1,:P1,i] for i in 1:9]
plot!(fcast3, color="red")