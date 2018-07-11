using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 4

tic()

include("monolith1.jl")


@resumable function start_sim(sim::Simulation,t::Number,w::Array,Θl::Array,ts::Array,te::Array)
    println("\n")
    println("   _[_]_   ")
    println("   (o,o)       Simulation started!!!")
    println("   ( : )   ")
    println("   ( : )   ")

    println("\n")
    println("Week #$t started...")

    for l in 1:N_products
        println("Slot $l:")
        for i in 1:N_products
            product = i
            if w[i,l,t] == 1
                tot_t = te[l,t]-ts[l,t] #tot_t: tiempo total del producto i en slot l de week t
                prod_t = Θl[i,l,t] #prod_t: tiempo de produccion de i en slot l de week t
                trans_t = tot_t-prod_t #trans_t: tiempo de transicion despues de la produccion de i en slot l de week t

                println("process time = ",now(sim))

                println("Product $i: took $tot_t hours in total")
                println("Product $i: took $prod_t hours of production")
                println("Product $i: took $trans_t hours of transition time")

                @yield timeout(sim,tot_t)

                println("process time = ",now(sim))
            end
        end
    end


    #=
    println("Lo que recibe la simu = ", x)
    falla = rand()
    println("falla = ", falla)

    srand(1)
    d = Normal(2,0.5);
    for i in 1:4
        t_falla = rand(d);
        println("t_falla = ", t_falla)
    end

    if falla < 0.5
        println("$falla \n")

        println("Start driving at ", now(sim))


    end

    time = now(sim)
    =#


end


#1. Se crean los parametros iniciales: la demanda y el inventario inicial
srand(123)
d = Normal(14333.33333, 10631.595)
Dem = rand(d, N_products, N_periods)

INVI = [0 for i in 1:5]

#2. Se crean los vectores que almacenaran la informacion de la opti y la simu
x_pass = -1*ones(Float64, N_periods, N_products, N_periods)
invo_pass = -1*ones(Float64, N_periods, N_products, N_periods)
w_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
Θl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
te_pass = -1*ones(Float64, N_periods, N_products, N_periods)
ts_pass = -1*ones(Float64, N_periods, N_products, N_periods)

#3. Se hace un for que recorre cada semana
for t_index in 1:N_periods
    println("\n")
    println("                 ^__^")
    println("                 (oo)\\______")
    println("   Well Done    (__)\\       )\\/\\")
    println("                     ||---- |")
    println("                     ||    ||          Empieza la semana #$t_index")

    println("\n")
    println("Dem = ",Dem)
    println("\n")

    #4. Se resuelve el problema de opti (Trabajo del Planner/Scheduler)

    if isodd(t_index) == true
        m = monolith(Dem,N_products,N_periods,INVI)

        solve(m)

        x = getindex(m, :x);
        x_sol = getvalue(x)
        invo = getindex(m, :invo);    invo_sol = getvalue(invo)
        w = getindex(m, :w);    w_sol = getvalue(w)
        Θl = getindex(m, :Θl);    Θl_sol = getvalue(Θl)
        ts = getindex(m, :ts);    ts_sol = getvalue(ts)
        te = getindex(m, :te);    te_sol = getvalue(te)

        #5. Se almacenan los resultados de la opti
        x_pass[t_index,:,:] = x_sol[:,:]
        invo_pass[t_index,:,:] = invo_sol[:,:];
        w_pass[t_index,:,:,:] = w_sol[:,:,:]
        Θl_pass[t_index,:,:,:] = Θl_sol[:,:,:]
        ts_pass[t_index,:,:] = ts_sol[:,:]
        te_pass[t_index,:,:] = te_sol[:,:]
    else
        m = monolith(Dem,N_products,N_periods,INVI)

        x = getindex(m, :x);

        setlowerbound.(x[:,t_index],x_pass[t_index-1,:,t_index]);
        setupperbound.(x[:,t_index],x_pass[t_index-1,:,t_index]);

        solve(m)

        x_sol = getvalue(x)
        invo = getindex(m, :invo);    invo_sol = getvalue(invo)
        w = getindex(m, :w);    w_sol = getvalue(w)
        Θl = getindex(m, :Θl);    Θl_sol = getvalue(Θl)
        ts = getindex(m, :ts);    ts_sol = getvalue(ts)
        te = getindex(m, :te);    te_sol = getvalue(te)

        #5. Se almacenan los resultados de la opti
        x_pass[t_index,:,:] = x_sol[:,:]
        invo_pass[t_index,:,:] = invo_sol[:,:];
        w_pass[t_index,:,:,:] = w_sol[:,:,:]
        Θl_pass[t_index,:,:,:] = Θl_sol[:,:,:]
        ts_pass[t_index,:,:] = ts_sol[:,:]
        te_pass[t_index,:,:] = te_sol[:,:]
    end


    #6. Se realiza la simulacion para la semana t_index
    sim = Simulation()
    @process start_sim(sim,t_index,w_pass[t_index,:,:,:],Θl_pass[t_index,:,:,:],ts_pass[t_index,:,:],te_pass[t_index,:,:])
    run(sim)

    #7. Se actualiza la informacion de la demanda y el inventario
    for tt in 1:N_periods
        if tt < N_periods
            Dem[:,tt] = Dem[:,tt+1]
        else
            Dem[:,tt] = rand(d, N_products)
        end
    end
    for i in 1:N_products
        for t in 1:N_periods
            if Dem[i,t] < 0
                Dem[i,t] = -Dem[i,t]
            end
        end
    end

    INVI = invo_sol[:,t_index]

    println("INVI = ",INVI)

end

println("\n")
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
#materia prima = Relacionar productos con materia prima y agregar incertidumbre
#sobre la cantidad de materia prima demanda diaria
