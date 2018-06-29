using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

tic()

include("monolith.jl")

@resumable function Customer(sim::Simulation)
    srand(123)
    d=Normal(14333.33333,10631.595);
    Dem1=rand(d,5);Dem2=rand(d,5);Dem3=rand(d,5);Dem4=rand(d,5);
    Dem=hcat(Dem1,Dem2,Dem3,Dem4)

    #=
    Dem = [
            0           10000       20000       0
            15000       10000       5000        15000
            20000       30000       40000       20000
            20000       10000       3000        20000
            20000       10000       2000        20000]
    =#
end

@resumable function Planner(sim::Simulation, Dem::Array{Float64,2}, m::Model)
    x = getindex(m, :x)

    solve(m)

    x_sol = getvalue(x) #x_sol = Solucion de x

    @show getsolvetime(m)

    (x, x_sol)
end

@resumable function Proc(sim::Simulation, x::Float64)
    fail_prob = 0.5

    #srand(123)
    #d=Exponential()
    #fail=rand(d)

    fail = rand()

    if fail <= fail_prob
        metric = x+3
        println("Hubo un fallo :(")
    else
        metric = x+1
        println("No hubo ningún fallo :)")
    end
    println("Fail = ", fail)
    metric
end

@resumable function start_sim(sim::Simulation)
    Customer_process = @process Customer(sim)
    Dem = @yield Customer_process

    N_products = 5
    N_periods = 3

    m = monolith(Dem,N_products,N_periods)

    for t_index in 1:3
        println("Dem = ",Dem)

        println("\n")
        println("                 ^__^")
        println("                 (oo)\\______")
        println("   Well Done    (__)\\       )\\/\\    iter = $t_index")
        println("                     ||---- |")
        println("                     ||    ||")
        println("\n");

        Plan_process = @process Planner(sim, Dem, m)
        (x, x_sol) = @yield Plan_process

        println("Output de Planner = ", x_sol)

        setlowerbound(x[:,1],1)
        #if t_index > 1
        #    for (i,t) in keys(x)
        #        println(t_index)
        #        #setlowerbound(x[i,t_index-1],1)
        #        #setupperbound(x[i,t_index-1],getvalue(x[i,t-1]))
        #    end
        #end

        #=
        m2 = monolith(Dem,N_products,N_periods)
        x2 = getindex(m2, :x)

        =#

        #=srand(123)
        d=Normal(14333.33333,10631.595);
        Dem1=rand(d,5);

        srand(23)
        d=Normal(14333.33333,10631.595);
        Dem2=rand(d,5);Dem3=rand(d,5);Dem4=rand(d,5);
        Dem=hcat(Dem1,Dem2,Dem3,Dem4)

        println(Dem)
        =#
    end

    #Aca deberia ir el @process de Proc
end

sim = Simulation()
@process start_sim(sim)
run(sim)

println("                  _                        _       _             _   _   _")
println("  ____    ____   | |   ____    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / _ _\\  / __ \\  | |  / __ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (_ _  | (__) | | | | (__) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\____/  \\____/  |_|  \\____/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")
println("\n")

toc()

#Parametros con incertidumbre
#τ[i,k] = transition time from product i to product k
#R[i] = production rates
#materia prima = Relacionar productos con materia prima y agregar incertidumbre sobre la cantidad de materia prima
#demanda diaria
