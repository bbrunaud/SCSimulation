tic()

using ResumableFunctions
using SimJulia
using Distributions

include("monolith3.jl")

# On the main code we define the following parameters because (1) they have
# uncertainty or (2) they allow communication between simulation agents:
#   - TABLE D(I,T)      DEMAND FOR PRODUCT I AT THE END OF PERIOD T
#   - PARAMETER R(I)    PRODUCTION RATES FOR PRODUCTS
#   - PARAMETER INVI(I) INITIAL INVENTORY AT HAND
mutable struct SCSimulationData
    Dem     # DEMAND FOR PRODUCT I AT THE END OF PERIOD T
    R       # PRODUCTION RATES FOR PRODUCTS
    INVI    # INITIAL INVENTORY AT HAND
    Winit
    list    # Communication between planner and operator
    t_index # Actual period (week) of simulation
    fail
    sells
end

N_products = 5
N_periods = 2
#N_machines = 1

function SCSimulationData()
    Dem = [0.0          10000        20000        0
            15000        10000        5000        15000
            20000        30000        40000       20000
            20000        10000        3000        20000
            20000        10000        2000        20000]

    R = [800.0  900  1000 1000 1200]

    INVI = [0.0 for i in 1:N_products]

    Winit = [0 for i in 1:N_products]

    list = -1*ones(N_products,4)

    t_index = 0

    fail = 0

    sells = -1*ones(N_products)

    s = SCSimulationData(Dem,R,INVI,Winit,list,t_index,fail,sells)
end

srand(123456)
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
    w = getindex(m,:w);             w_sol = getvalue(w)
    Θl = getindex(m,:Θl);           Θl_sol = getvalue(Θl)
    xl = getindex(m,:xl);           xl_sol = getvalue(xl)
    ts = getindex(m,:ts);           ts_sol = getvalue(ts)
    te = getindex(m,:te);           te_sol = getvalue(te)
    invo = getindex(m,:invo);       invo_sol = getvalue(invo)
    inv = getindex(m,:inv);         inv_sol = getvalue(inv)
    s = getindex(m,:s);             s_sol = getvalue(s)

    println("w_sol = $(w_sol[:,:,1])")
    println("xl_sol = $(xl_sol[:,:,1])")
    println("inv_sol = $(inv_sol[:,1])")
    println("s_sol = $(s_sol[:,1])")
    println("invo_sol = $(invo_sol[:,1])")

    # list representa la lista de trabajos que el operario debe hacer. Comunica la siguiente informacion:
    # 1. cuál es el producto que se debe producir
    # 2. cuánto es el tiempo de produccion
    # 3. cuánto es el tiempo de transicion
    # 4. cuánto se desea producir del producto en cuestion
    for l in 1:N_products
        for i in 1:N_products
            if w_sol[i,l,1] > 0.9
                tot_t = te_sol[l,1]-ts_sol[l,1] #tot_t: tiempo total del producto i en slot l de week t
                prod_t = Θl_sol[i,l,1] #prod_t: tiempo de produccion de i en slot l de week t
                trans_t = tot_t - prod_t #trans_t: tiempo de transicion despues de la produccion de i en slot l de week t

                sc.list[l,1] = i
                sc.list[l,2] = prod_t
                sc.list[l,3] = round(trans_t,2)
                sc.list[l,4] = xl_sol[i,l,1]
                #sc.list[l,5] = s_sol[i,1]   # Lo que se planea vender
                #sc.list[l,6] = inv_sol[i,1]
            end
        end
    end

    # sells aporta info sobre cuánto se desea vender de todos los productos en la semana de estudio
    sc.sells[:] = s_sol[:,1]
    println("sc.sells = $(sc.sells)")
end

# The "Planner" agent is responsible for optimizing the model every two weeks
@resumable function planner(env::Simulation,sc::SCSimulationData)
    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods)
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
    @yield timeout(env,-now(sim))
    println("\n")
    cond = true


    for l in 1:N_products
        i_ind = sc.list[l,1]
        prod_t = sc.list[l,2]
        trans_t = sc.list[l,3]
        xl = sc.list[l,4]
        if cond == true
            println("Product $(i_ind) was produced in slot $l of week $(sc.t_index)")

            # Incertidumbre en el rendimiento
            if prod_t > 0
                d_R = Normal(sc.R[convert(Int64,i_ind)]-50,50) #Distribucion normal para incertidumbre del rendimiento R[i]
                R_alea = rand(d_R)
                prod_t = sc.list[l,4]/R_alea
                println("       The theoretical production time was of $(round(prod_t,2)) hr, but it was of $(round(prod_t,2)) hr")
                prod_t = prod_t
            else
                println("       Product $(i_ind) did not have any production time in slot $l")
            end

            # Incertidumbre en el tiempo de transicion
            if sc.list[l,3] >= 0.5 #Es 0.5 porque no cambia el tiempo de trans si este es igual a 0 y 0.5 es el minimo de τ
                d_trans_t = Normal(sc.list[l,3]+0.2,0.2)    #Distribucion normal para el tiempo de transicion
                trans_t = rand(d_trans_t)
                println("       The theoretical transition time was of $(sc.list[l,3]) hr, but it was of $(round(trans_t,2)) hr")
                sc.list[l,3] = trans_t
            else
                println("       Product $(i_ind) did not have any transition time in slot $l")
            end

            @yield timeout(env,prod_t+sc.list[l,3])
            println("       Tiempo de la semana $l = ",now(sim))

            if round(now(sim),1) <= 168.0
                # Actualizacion del inventario por produccion y venta de un producto
                if prod_t > 0
                    println("invi antes = $(sc.INVI[convert(Int64,i_ind)])")
                    sc.INVI[convert(Int64,i_ind)] += sc.list[l,4] - sc.sells[convert(Int64,i_ind)]
                    println("invi despues = $(sc.INVI[convert(Int64,i_ind)])")
                else
                    println("El inventario no fue actualizado para el slot $l de la semana $(sc.t_index)")
                end
            else
                t_delay = round(now(sim),1)-168.0

                println("   Se acabo la semana $(sc.t_index) y quedaron trabajos pendientes!!!")
                println("   el trabajo $l iba a durar $t_delay horas de mas")
                cond = false

                #sc.Winit a Winit le interesa almacenar informacion si el ultimo lote se estaba PRODUCIENDO (ie tiempo de produccion > 0)
                #Falta actualizar Winit
                #hacer que si el ultimo slot es de trans entonces el primer slot de la siguiente semana debe ser el de transicion
                #hacer que si el ultimo slot es de prod podria hacerse en el tiempo de delay pero entonces ?se deberia completar la siguiente semana o mejor no se hace y se pierde todo?
            end
        end
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
@process start_sim(sim,s)

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
