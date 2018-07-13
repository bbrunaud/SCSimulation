tic()

using ResumableFunctions
using SimJulia
using Distributions

include("monolith3.jl")

# On the main code we define the following parameters because (1) they have
# uncertainty or (2) they allow communication between simulation agents:
#   - TABLE TAU(I,K)    TRANSITION TIME FROM PROD I TO K
#   - TABLE D(I,T)      DEMAND FOR PRODUCT I AT THE END OF PERIOD T
#   - PARAMETER R(I)    PRODUCTION RATES FOR PRODUCTS
#   - PARAMETER INVI(I) INITIAL INVENTORY AT HAND
mutable struct SCSimulationData
    τ       # TRANSITION TIME FROM PROD I TO K
    Dem     # DEMAND FOR PRODUCT I AT THE END OF PERIOD T
    R       # PRODUCTION RATES FOR PRODUCTS
    INVI    # INITIAL INVENTORY AT HAND
    Winit
    list    # List of work to be done (communication between planner and operator)
    t_index # Actual period (week) of simulation
end

N_products = 5
N_periods = 2
#N_machines = 1

function SCSimulationData()
    τ = [0     2     1.5     1       0.75
    1     0      2     0.75     0.5
    1     1.25   0      1.5      2
    0.5   1      2      0       1.75
    0.7   1.75   2      1.5       0]

    Dem = [0.0          10000        20000        0
            15000        10000        5000        15000
            20000        30000        40000       20000
            20000        10000        3000        20000
            20000        10000        2000        20000]

    R = [800.0  900  1000 1000 1200]

    INVI = [0 for i in 1:N_products]

    Winit = [0 for i in 1:N_products]

    list = zeros(N_products,5)

    t_index = 0

    s = SCSimulationData(τ,Dem,R,INVI,Winit,list,t_index)
end

srand(123)
d_dem = Normal(14333.33333,10631.595)

# The "client" agent is responsible for generating the demand in each period
@resumable function client(env::Simulation,sc::SCSimulationData)
    #sc.Dem[:,sc.t_index] = rand(d_dem,N_products)
    for t in 1:N_periods-1
        sc.Dem[:,t] = sc.Dem[:,t+1]
    end
    sc.Dem[:,end] = rand(d_dem,N_products)

    # None of the generated numbers should be negative
    for i in 1:N_products
        for t in 1:N_periods
            if sc.Dem[i,t] < 0
                sc.Dem[i,t] = -sc.Dem[i,t]
            end
        end
    end
end

# Esta es la funcion que transforma la solucion del problema de opti en una lista sencial!
# es decir que "transformation" es lo unico que se debe cambiar de simu.jl cuando se trabaja otro modelo
function transformation(m::JuMP.Model,sc::SCSimulationData)
    w = getindex(m,:w);                w_sol = getvalue(w)
    Θl = getindex(m,:Θl);              Θl_sol = getvalue(Θl)
    xl = getindex(m,:xl);              xl_sol = getvalue(xl)
    ts = getindex(m,:ts);              ts_sol = getvalue(ts)
    te = getindex(m,:te);              te_sol = getvalue(te)

    for l in 1:N_products
        for i in 1:N_products
            if w_sol[i,l,sc.t_index] > 0.9
                tot_t = te_sol[l,sc.t_index]-ts_sol[l,sc.t_index] #tot_t: tiempo total del producto i en slot l de week t
                prod_t = Θl_sol[i,l,sc.t_index] #prod_t: tiempo de produccion de i en slot l de week t
                trans_t = tot_t - prod_t #trans_t: tiempo de transicion despues de la produccion de i en slot l de week t

                sc.list[l,1] = i
                sc.list[l,2] = ts_sol[l,sc.t_index]
                sc.list[l,3] = prod_t
                sc.list[l,4] = trans_t
                sc.list[l,5] = xl_sol[i,l,sc.t_index]
            end
        end
    end
end

# The "Planner" agent is responsible for optimizing the model every two weeks
@resumable function planner(env::Simulation,sc::SCSimulationData)
    m = monolith(sc.τ,sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods)
    status = solve(m)

    tic()
    status = solve(m)
    m_time = toc()

    println("\n")
    println("   (\\ _ /)      Solve status was $status")
    println("   ( 'x' )        ")
    println("   c(\")(\")      Problem was solved in $m_time sec")

    transformation(m,sc)

    # Se deben tener en cuenta los backlogs
end

@resumable function operator(env::Simulation,sc::SCSimulationData)
    println("$(sc.list)")
    for l in 1:N_products
        println("Product $(sc.list[l,1]) was produced in slot $l of week $(sc.t_index)")

        # Incertidumbre en el tiempo de transicion
        if sc.list[l,4] >= 0.5 #Es 0.5 porque no cambia el tiempo de trans si este es igual a 0 y 0.5 es el minimo de τ
            d_trans_t = Normal(sc.list[l,4],0.2)    #Distribucion normal para el tiempo de transicion
            trans_t = rand(d_trans_t)
            println("The theoretical transition time was of $(round(sc.list[l,4],2)) hr, but it was of $(round(trans_t,2)) hr")
            sc.list[l,4] = trans_t
        else
            println("Product $(sc.list[l,1]) did not have any transition time in slot $l")
        end

        # Incertidumbre en el rendimiento
        #d_R = Normal(R[i],50) #Distribucion normal para incertidumbre del rendimiento R[i]
        #R_alea = rand(d_R)

        #prod_t = xl_pass[t_ind,i,l,t]/R[i]
        #println("Product $i: the real production time was of ",round(prod_t,3)," hours")

        #R[i] = R_pass

        println("The theoretical production time was of $(round(sc.list[l,3],2)) hr")#, but it was of $(round(trans_t,2)) hr")

        @yield timeout(env,sc.list[l,3]+sc.list[l,4])
        println("process time = ",now(sim))
    end
end

@resumable function start_sim(env::Simulation,sc::SCSimulationData)
    for t_ind in 1:N_periods
        sc.t_index = t_ind
        println("\n")
        println("    ^__^               ")
        println("    (oo)\\______       ")
        println("   (__)\\       )\\/\\ ")
        println("        ||---- |       ")
        println("        ||    ||       Week #$(sc.t_index) started!")

        if t_ind > 1
            client_process = @process client(env,sc)
            @yield client_process
        end

        planner_process = @process planner(env,sc)
        @yield planner_process

        operator_process = @process operator(env,sc)
        @yield operator_process
    end
end

s = SCSimulationData()
sim = Simulation()
@process start_sim(sim, s)

run(sim)

println("\n")
println("                   _                       _       _             _   _   _")
println("     ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
println("    / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("   | (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println("    \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")

println("\n")
toc()

#=
println("\n")
println("    /\\__/\\      ")
println("   (=^.^=)        ")
println("    (\")(\")_/    ")

println("\n")
println("   _[_]_   ")
println("   (o,o)   ")
println("   ( : )   ")
println("   ( : )   ")
=#
