using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 5

tic()

include("monolith.jl")

@resumable function start_sim(sim::Simulation)
    srand(123)
    d=Normal(14333.33333,10631.595);
    #Dem1=rand(d,5);Dem2=rand(d,5);Dem3=rand(d,5);Dem4=rand(d,5);
    #Dem=hcat(Dem1,Dem2,Dem3,Dem4)

    ##=
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
    #convert(Array{Float64,2},Dem)
    ##=#


    for t_index in 1:N_periods
        println("\n")
        println("                 ^__^")
        println("                 (oo)\\______")
        println("   Well Done    (__)\\       )\\/\\")
        println("                     ||---- |")
        println("                     ||    ||          iter = $t_index")
        println("\n");

        if t_index == 1
            println("Dem = ",Dem)

            m = monolith(Dem, N_products, N_periods)

            solve(m)

            w = getindex(m, :w);                w_sol = getvalue(w);                w_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);            w_pass[1,:,:,:] = w_sol[:,:,:];
            Θl = getindex(m, :Θl);              Θl_sol = getvalue(Θl);              Θl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           Θl_pass[1,:,:,:] = Θl_sol[:,:,:];
            xl = getindex(m, :xl);              xl_sol = getvalue(xl);              xl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           xl_pass[1,:,:,:] = xl_sol[:,:,:];
            Θ = getindex(m, :Θ);                Θ_sol = getvalue(Θ);                Θ_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        Θ_pass[1,:,:] = Θ_sol[:,:];
            x = getindex(m, :x);                x_sol = getvalue(x);                x_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        x_pass[1,:,:] = x_sol[:,:];
            z = getindex(m, :z);                z_sol = getvalue(z);                z_pass = -1*ones(Float64, N_periods, N_products, N_products, N_products, N_periods);z_pass[1,:,:,:,:] = z_sol[:,:,:,:];
            te = getindex(m, :te);              te_sol = getvalue(te);              te_pass = -1*ones(Float64, N_periods, N_products, N_periods);                       te_pass[1,:,:] = te_sol[:,:];
            ts = getindex(m, :ts);              ts_sol = getvalue(ts);              ts_pass = -1*ones(Float64, N_periods, N_products, N_periods);                       ts_pass[1,:,:] = ts_sol[:,:];
            trt = getindex(m, :trt);            trt_sol = getvalue(trt);            trt_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);          trt_pass[1,:,:,:] = trt_sol[:,:,:];
            inv = getindex(m, :inv);            inv_sol = getvalue(inv);            inv_pass = -1*ones(Float64, N_periods, N_products, N_periods);                      inv_pass[1,:,:] = inv_sol[:,:];
            invo = getindex(m, :invo);          invo_sol = getvalue(invo);          invo_pass = -1*ones(Float64, N_periods, N_products, N_periods);                     invo_pass[1,:,:] = invo_sol[:,:];
            s = getindex(m, :s);                s_sol = getvalue(s);                s_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        s_pass[1,:,:] = s_sol[:,:];
            area = getindex(m, :area);          area_sol = getvalue(area);          area_pass = -1*ones(Float64, N_periods, N_products, N_periods);                     area_pass[1,:,:] = area_sol[:,:];

            println("Output de Planner = ", x_sol)
        else
            #Dem[:,t_index] = rand(d,N_products);
            Dem[:,t_index] = Dem[:,t_index] + 3*rand()
            println("Dem = ",Dem)

            m = monolith(Dem, N_products, N_periods)
            x = getindex(m, :x)

            for iter in 2:t_index
            setlowerbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);
            setlowerbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);
            setlowerbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);
            setlowerbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);
            setlowerbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);
            setlowerbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);
            setlowerbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);
            setlowerbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);
            setlowerbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);
            setlowerbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);
            setlowerbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);
            setlowerbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);
            setlowerbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);

            setupperbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);
            setupperbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);
            setupperbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);
            setupperbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);
            setupperbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);
            setupperbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);
            setupperbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);
            setupperbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);
            setupperbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);
            setupperbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);
            setupperbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);
            setupperbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);
            setupperbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);
            end

            solve(m)
            x_sol = getvalue(x) #x_sol = Solucion de x

            println("Output de Planner = ", x_sol)

            x_pass[t_index,:,:] = x_sol[:,:]
        end
    end
    #Aca deberia ir el @process de Proc
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
