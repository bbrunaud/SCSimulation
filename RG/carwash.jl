# Este es un ejemplo de simulacion de varias maquinas en paralelo utilizando
# request de SimJulia

using ResumableFunctions
using SimJulia
using DataFrames

N_rsc = 5
N_slots = 3

df = DataFrame(Iteration=[],Plant=[],Backlog=[])

Orders = zeros(N_rsc,N_slots,4)

# Ejemplo de Erdirik Model 2.pdf
#product    ts      tp      trt
Orders[1,:,:] = [
6   0       70      6
3   76      20      12
2   108     60      0
]
Orders[2,:,:] = [
9   0       25      6
8   31      33      12
2   76      92      0
]
Orders[3,:,:] = [
1   0       70      6
7   76      50      4
4   130     38      0
]
Orders[4,:,:] = [
2   0       0       0
2   0       0       0
2   0       168     0
]
Orders[5,:,:] = [
5   0       30      10
10  40      75      12
3   127     41      0
]

@resumable function plant(sim::Simulation, rsc::Resource, u::Number, l::Number, p::Number, ini_t::Number, prod_t::Number, trans_t::Number)
    @yield timeout(sim, ini_t)
    #println("Product $p was assigned to unit $u at $(round(now(sim),2)) of week (sc.t_index) (slot $l)")

    @yield request(rsc)
    println("   Unit $u started to work with product $p (slot $l of week (sc.t_index)) at $(round(now(sim),2))")

    # Uncertainty of production rate: Normal distribution
    # The uncertainty should only be applied if there is any production time
    if prod_t > 0
        #d_R = Normal(sc.R[convert(Int64,i_ind)]-45,50) TODO: Descomentar esto cuando se pase al modelo original
        #R_alea = rand(d_R)
        #prod_t_alea = xl/R_alea
        prod_t_alea = prod_t + rand(1:10)               #TODO: Esta linea NO debe ir en el modelo original
        println("       The production time of product $p in unit $u (slot $l) was $(round(prod_t_alea,2)) hr (), but it was of $(round(prod_t,2)) ")
        prod_t = prod_t_alea
    else
        println("       Product $p in unit $u (slot $l) did not have any production time")
    end
    @yield timeout(sim, prod_t)

    # Uncertainty of transition time: Normal distribution
    # The uncertainty should only be applied if there is any transition time
    # trans_t >= 0.5 is because that is the minimal transition time in the model
    if trans_t >= 0.5
        #d_trans_t = Normal(trans_t+0.1,0.2)    TODO: Descomentar esto cuando se pase al modelo original
        #trans_t_alea = rand(d_trans_t)
        trans_t_alea = trans_t + rand()         #TODO: Esta linea NO debe ir en el modelo original
        println("       The theoretical transition time of product $p in unit $u (slot $l) was of $(round(trans_t,2)) hr, but it was of $(round(trans_t_alea,2)) hr")
        trans_t = trans_t_alea
    else
        println("       Product $p in unit $u (slot $l) did not have any transition time")
    end
    @yield timeout(sim, trans_t)

    #TODO: Descomentar esto cuando se pase al modelo original
    # Uncertainty of failure: If there was a failure, then
    # the a failure time is going to be added to the total time
    #=if now(sim) >= sc.fail_time[1]
        # Set up the new failure time
        sc.fail_time = fail_machine(now(env))

        # The process had a failure
        println("---------->There was a failure of $(round(sc.fail_time[2],2)) hours in slot $l of week $(sc.t_index)")
        println("           Next failure will happen in $(round(sc.fail_time[1],2))")
        @yield timeout(env,sc.fail_time[2])
    end=#

    println("   Product $p is leaving unit $u at $(round(now(sim),2))")
    @yield release(rsc)
end

sim = Simulation()

rsc = []
for i in 1:N_rsc
    push!(rsc,Resource(sim, 1))
end

for r in 1:N_rsc
    for l in 1:N_slots
        @process plant(sim, rsc[r], r, l, Orders[r,l,1], Orders[r,l,2], Orders[r,l,3], Orders[r,l,4])
    end

    #push!(df,[i,"Pitt",rand(1:100)])

end

srand(1234567890)
run(sim)

println("\n")
println("                _                       _       _             _   _   _")
println("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")
