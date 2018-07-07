using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 2

tic()

include("monolith1.jl")

@resumable function start_sim(sim::Simulation)
    #TABLE D(I,T)      DEMAND FOR PRODUCT I AT THE END OF PERIOD T
    srand(123)
    d=Normal(14333.33333,10631.595);
    Dem = rand(d, N_products, N_periods);

    #=
    D1 = [
              0.0        10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0
            15000        10000        5000        15000        10000        5000        15000        10000        5000        15000        10000        5000        15000        10000        5000        15000
            20000        30000        40000       20000        30000        40000       20000        30000        40000       20000        30000        40000       20000        30000        40000       20000
            20000        10000        3000        20000        10000        3000        20000        10000        3000        20000        10000        3000        20000        10000        3000        20000
            20000        10000        2000        20000        10000        2000        20000        10000        2000        20000        10000        2000        20000        10000        2000        20000
    ]

    D2 = [
           10000        20000        0           10000        20000        0           10000        20000
           10000        5000        15000        10000        5000        15000        10000        5000
           30000        40000       20000        30000        40000       20000        30000        40000
           10000        3000        20000        10000        3000        20000        10000        3000
           10000        2000        20000        10000        2000        20000        10000        2000
    ]

    Dem = hcat(D1,D2)
    =#
    #PARAMETER INVI(I)  INITIAL INVENTORY AT HAND
    INVI = [0 for i in 1:5]

    for t_index in 1:N_periods
        println("Dem = ",Dem)

        m = monolith(Dem, N_products, N_periods, INVI)
        solve(m)
        x = getindex(m, :x);    x_sol = getvalue(x)
        invo = getindex(m, :invo);    invo_sol = getvalue(invo)
        println("x_sol = ", x_sol)

        for tt in 1:N_periods
            if tt < N_periods
                Dem[:,tt] = Dem[:,tt+1]
            else
                Dem[:,tt] = rand(d, N_products)
            end
        end
        INVI = invo_sol[:,t_index]
    end
end


sim = Simulation()
@process start_sim(sim)
run(sim)

println("                _                       _       _             _   _   _")
println("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")
println("\n")

toc()

#DEBO HALLAR LA MANERA DE GUARDAR LAS SOLUCIONES PARA HACER EL
#"ROLLING HORIZON"

#Parametros con incertidumbre
#τ[i,k] = transition time from product i to product k
#R[i] = production rates
#materia prima = Relacionar productos con materia prima y agregar incertidumbre sobre la cantidad de materia prima
#demanda diaria
