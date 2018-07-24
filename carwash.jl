# Este es un ejemplo de simulacion de varias maquinas en paralelo utilizando
# request de SimJulia

using ResumableFunctions
using SimJulia
using DataFrames

N_rsc = 2
N_slots = 4

df = DataFrame(Iteration=[],Plant=[],Backlog=[])

Orders = zeros(N_rsc,N_slots,4)

#                   product ts      tp      trt
Orders[1,:,:] = [   3       0       40      0
                    1       40      110     5
                    2       155     100     10
                    3       265     300     0]
Orders[2,:,:] = [   4       0       93      12
                    5       105     180     10
                    3       190     310     0
                    3       500     0       0]

@resumable function operator(sim::Simulation, prod::Number, rsc::Resource, driving_time::Number, charge_duration::Number, machine::Number)
    @yield timeout(sim, driving_time)
    println("   Product $prod was assigned to slot $l of week $(sc.t_index)")
    println("   $name arriving at $(now(sim)) to machine $machine")
    @yield request(rsc)
    println("   $name starting to charge at $(now(sim)) in machine $machine")
    @yield timeout(sim, charge_duration)
    println("   $name leaving the bcs at $(now(sim)) of machine $machine")
    @yield release(rsc)
end

sim = Simulation()

rsc = []
for i in 1:2
    push!(rsc,Resource(sim, 1))
end

for r in 1:N_rsc
    for l in 1:N_slots
        @process operator(sim, Orders[r,l,1], rsc[1], 2i, 5, 1)
    end

    #push!(df,[i,"Pitt",rand(1:100)])

end

run(sim)
