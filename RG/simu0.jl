using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 4

tic()

include("monolith.jl")

@resumable function start_sim(sim::Simulation)
    srand(123)
    d=Normal(14333.33333,10631.595);
    #Dem1=rand(d,5);Dem2=rand(d,5);Dem3=rand(d,5);Dem4=rand(d,5);
    #Dem=hcat(Dem1,Dem2,Dem3,Dem4)
    Dem1=rand(d,5);
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
            #println("Dem = ",Dem)

            m = monolith(Dem, N_products, N_periods)

            solve(m)
            x = getindex(m, :x);                x_sol = getvalue(x);                x_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        x_pass[1,:,:] = x_sol[:,:];

            #Solucion de todas las variables para la primera iteracion
            var_pass = -1*ones(N_periods, length(m.colVal))
            var_pass[1,:] = m.colVal

            w = getindex(m, :w);                w_sol = getvalue(w);                w_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);            w_pass[1,:,:,:] = w_sol[:,:,:];
            Θl = getindex(m, :Θl);              Θl_sol = getvalue(Θl);              Θl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           Θl_pass[1,:,:,:] = Θl_sol[:,:,:];
            xl = getindex(m, :xl);              xl_sol = getvalue(xl);              xl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           xl_pass[1,:,:,:] = xl_sol[:,:,:];
            Θ = getindex(m, :Θ);                Θ_sol = getvalue(Θ);                Θ_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        Θ_pass[1,:,:] = Θ_sol[:,:];
            z = getindex(m, :z);                z_sol = getvalue(z);                z_pass = -1*ones(Float64, N_periods, N_products, N_products, N_products, N_periods);z_pass[1,:,:,:,:] = z_sol[:,:,:,:];
            te = getindex(m, :te);              te_sol = getvalue(te);              te_pass = -1*ones(Float64, N_periods, N_products, N_periods);                       te_pass[1,:,:] = te_sol[:,:];
            ts = getindex(m, :ts);              ts_sol = getvalue(ts);              ts_pass = -1*ones(Float64, N_periods, N_products, N_periods);                       ts_pass[1,:,:] = ts_sol[:,:];
            trt = getindex(m, :trt);            trt_sol = getvalue(trt);            trt_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);          trt_pass[1,:,:,:] = trt_sol[:,:,:];
            inv = getindex(m, :inv);            inv_sol = getvalue(inv);            inv_pass = -1*ones(Float64, N_periods, N_products, N_periods);                      inv_pass[1,:,:] = inv_sol[:,:];
            invo = getindex(m, :invo);          invo_sol = getvalue(invo);          invo_pass = -1*ones(Float64, N_periods, N_products, N_periods);                     invo_pass[1,:,:] = invo_sol[:,:];
            s = getindex(m, :s);                s_sol = getvalue(s);                s_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        s_pass[1,:,:] = s_sol[:,:];
            area = getindex(m, :area);          area_sol = getvalue(area);          area_pass = -1*ones(Float64, N_periods, N_products, N_periods);                     area_pass[1,:,:] = area_sol[:,:];

            println("Output de Planner = ", x_sol)

            #println("area = ", area_sol)
            #println("calculo = ", (0 + x_sol[:,:])*168)

        else
            #Dem[:,t_index] = rand(d,N_products);
            Dem[:,t_index] = Dem[:,t_index] + 3*rand()
            #println("Dem = ",Dem)

            m = monolith(Dem, N_products, N_periods)
            x = getindex(m, :x);

            w = getindex(m, :w);
            Θl = getindex(m, :Θl);
            xl = getindex(m, :xl);
            Θ = getindex(m, :Θ);
            z = getindex(m, :z);
            te = getindex(m, :te);
            ts = getindex(m, :ts);
            trt = getindex(m, :trt);
            inv = getindex(m, :inv);
            invo = getindex(m, :invo);
            s = getindex(m, :s);
            area = getindex(m, :area);

            for iter in 2:t_index
                 println("   _[_]_   ")
                 println("   (o,o)   ")
                 println("   ( : )   ")
                 println("   ( : )   ")
                 println("   ")
                 #println("w_pass = ", w_pass[t_index-1,:,:,iter-1])
                 #println("Θl_pass = ", Θl_pass[t_index-1,:,:,iter-1])
                 #println("xl_pass = ", xl_pass[t_index-1,:,:,iter-1])
                 #println("Θ_pass = ", Θ_pass[t_index-1,:,iter-1])
                 #println("x_pass = ", x_pass[t_index-1,:,iter-1])
                 #println("z_pass = ", z_pass[t_index-1,:,:,:,iter-1])
                 #println("te_pass = ", te_pass[t_index-1,:,iter-1])
                 #println("ts_pass = ", ts_pass[t_index-1,:,iter-1])
                 #println("trt_pass = ", trt_pass[t_index-1,:,:,iter-1])
                 #println("inv_pass = ", inv_pass[t_index-1,:,iter-1])
                 println("invo_pass = ", invo_pass[t_index-1,:,iter-1])
                 #println("s_pass = ", s_pass[t_index-1,:,iter-1])
                 #println("area_pass = ", area_pass[t_index-1,:,iter-1])
                 #println("calculo = ", R[:].*Θl_pass[t_index-1,:,l,t_index-1])


                 setlowerbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);             setupperbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);
                 setlowerbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);           setupperbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);
                 setlowerbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);           setupperbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);
                 setlowerbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);                 setupperbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);
                 setlowerbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);                 setupperbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);
                 setlowerbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);         setupperbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);
                 setlowerbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);               setupperbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);
                 setlowerbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);               setupperbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);
                 setlowerbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);         setupperbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);
                 setlowerbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);             setupperbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);
                 setlowerbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);           setupperbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);
                 setlowerbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);                 setupperbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);
                 setlowerbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);           setupperbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);
            end

            solve(m)

            w_sol = getvalue(w);                w_pass[t_index,:,:,:] = w_sol[:,:,:];
            Θl_sol = getvalue(Θl);              Θl_pass[t_index,:,:,:] = Θl_sol[:,:,:];
            xl_sol = getvalue(xl);              xl_pass[t_index,:,:,:] = xl_sol[:,:,:];
            Θ_sol = getvalue(Θ);                Θ_pass[t_index,:,:] = Θ_sol[:,:];
            x_sol = getvalue(x);                x_pass[t_index,:,:] = x_sol[:,:];
            z_sol = getvalue(z);                z_pass[t_index,:,:,:,:] = z_sol[:,:,:,:];
            te_sol = getvalue(te);              te_pass[t_index,:,:] = te_sol[:,:];
            ts_sol = getvalue(ts);              ts_pass[t_index,:,:] = ts_sol[:,:];
            trt_sol = getvalue(trt);            trt_pass[t_index,:,:,:] = trt_sol[:,:,:];
            inv_sol = getvalue(inv);            inv_pass[t_index,:,:] = inv_sol[:,:];
            invo_sol = getvalue(invo);          invo_pass[t_index,:,:] = invo_sol[:,:];
            s_sol = getvalue(s);                s_pass[t_index,:,:] = s_sol[:,:];
            area_sol = getvalue(area);          area_pass[t_index,:,:] = area_sol[:,:];

            println("Output de Planner = ", x_sol)
        end

        #=
        srand(123)
        R = [800.0  900  1000 1000 1200]
        INVI = [0 for i in 1:N_products]

        #println("Inv antes de alteracion de R(i) = ", inv_pass)
        #println("Sales antes de alteracion de R(i) = ", s_pass)
        #println("Invo antes de alteracion de R(i) = ", invo_pass)

        #println("x_pass[t_index,:,t_index] = ", x_pass[t_index,:,t_index])

        for i in 1:N_products
            if x_pass[t_index,i,t_index] != 0.0
               #println("x_pass[t_index,i,t_index] = ", x_pass[t_index,i,t_index])
               d2 = Normal(R[i],50)
               R[i] = rand(d2)
               R[i] = R[i]+50
               xl_pass[t_index,i,:,t_index] = R[i]*Θl_pass[t_index,i,:,t_index]
               x_pass[t_index,i,t_index] = sum(xl_pass[t_index,i,:,t_index])
               if t_index > 1
                    inv_pass[t_index,i,t_index] = invo_pass[t_index,i,t_index-1] + x_pass[i,t_index]
               else
                    inv_pass[t_index,i,t_index] = INVI[i] + x_pass[t_index,i,t_index]
               end
               invo_pass[t_index,i,t_index] = inv_pass[t_index,i,t_index] - s_pass[t_index,i,t_index]
               #hACER ECUACION 14
            end
        end
        #println("Inv despues de alteracion de R(i) = ", inv_pass)
        #println("Sales despues de alteracion de R(i) = ", s_pass)
        println("Invo despues de alteracion de R(i) = ", invo_pass)
        =#
        invo_pass[t_index,:,t_index] = invo_pass[t_index,:,t_index]+1
        println("Invo despues de alteracion de R(i) = ", invo_pass)
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

#=
using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 4

tic()

include("monolith.jl")

@resumable function Customer(sim::Simulation, b::Bool, index::Number)
    if b ==false
        srand(123)
        d=Normal(14333.33333,10631.595);
        #Dem1=rand(d,5);Dem2=rand(d,5);Dem3=rand(d,5);Dem4=rand(d,5);
        #Dem=hcat(Dem1,Dem2,Dem3,Dem4)
        Dem1=rand(d, N_periods);


        D1 = [
        0.0          10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0
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

    else
                if index >= 1
                        srand(123)
                        #Dem[:,t_index] = rand(d,N_products);
                        Dem[:,index] = Dem[:,index] + 3*rand()
                end
    end

end

@resumable function start_sim(sim::Simulation)
    Customer_process = @process Customer(sim, false, 0)
    Dem = @yield Customer_process
    println("Dem = ", Dem)

    for t_index in 1:N_periods
        println("\n")
        println("                 ^__^")
        println("                 (oo)\\______")
        println("   Well Done    (__)\\       )\\/\\")
        println("                     ||---- |")
        println("                     ||    ||          iter = $t_index")
        println("\n");

        if t_index == 1
            #println("Dem = ",Dem)

            m = monolith(Dem, N_products, N_periods)

            solve(m)
            x = getindex(m, :x);                x_sol = getvalue(x);                x_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        x_pass[1,:,:] = x_sol[:,:];

            w = getindex(m, :w);                w_sol = getvalue(w);                w_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);            w_pass[1,:,:,:] = w_sol[:,:,:];
            Θl = getindex(m, :Θl);              Θl_sol = getvalue(Θl);              Θl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           Θl_pass[1,:,:,:] = Θl_sol[:,:,:];
            xl = getindex(m, :xl);              xl_sol = getvalue(xl);              xl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods);           xl_pass[1,:,:,:] = xl_sol[:,:,:];
            Θ = getindex(m, :Θ);                Θ_sol = getvalue(Θ);                Θ_pass = -1*ones(Float64, N_periods, N_products, N_periods);                        Θ_pass[1,:,:] = Θ_sol[:,:];
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
            Customer_process = @process Customer(sim, true, t_index)
            Dem = @yield Customer_process
            println("Dem = ", Dem)

            m = monolith(Dem, N_products, N_periods)
            x = getindex(m, :x);

            w = getindex(m, :w);
            Θl = getindex(m, :Θl);
            xl = getindex(m, :xl);
            Θ = getindex(m, :Θ);
            z = getindex(m, :z);
            te = getindex(m, :te);
            ts = getindex(m, :ts);
            trt = getindex(m, :trt);
            inv = getindex(m, :inv);
            invo = getindex(m, :invo);
            s = getindex(m, :s);
            area = getindex(m, :area);

            for iter in 2:t_index
                    setlowerbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);             setupperbound.(w[:,:,iter-1],w_pass[t_index-1,:,:,iter-1]);
                    setlowerbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);           setupperbound.(Θl[:,:,iter-1],Θl_pass[t_index-1,:,:,iter-1]);
                    setlowerbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);           setupperbound.(xl[:,:,iter-1],xl_pass[t_index-1,:,:,iter-1]);
                    setlowerbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);                 setupperbound.(Θ[:,iter-1],Θ_pass[t_index-1,:,iter-1]);
                    setlowerbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);                 setupperbound.(x[:,iter-1],x_pass[t_index-1,:,iter-1]);
                    setlowerbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);         setupperbound.(z[:,:,:,iter-1],z_pass[t_index-1,:,:,:,iter-1]);
                    setlowerbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);               setupperbound.(te[:,iter-1],te_pass[t_index-1,:,iter-1]);
                    setlowerbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);               setupperbound.(ts[:,iter-1],ts_pass[t_index-1,:,iter-1]);
                    setlowerbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);         setupperbound.(trt[:,:,iter-1],trt_pass[t_index-1,:,:,iter-1]);
                    setlowerbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);             setupperbound.(inv[:,iter-1],inv_pass[t_index-1,:,iter-1]);
                    setlowerbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);           setupperbound.(invo[:,iter-1],invo_pass[t_index-1,:,iter-1]);
                    setlowerbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);                 setupperbound.(s[:,iter-1],s_pass[t_index-1,:,iter-1]);
                    setlowerbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);           setupperbound.(area[:,iter-1],area_pass[t_index-1,:,iter-1]);
            end

            solve(m)

            w_sol = getvalue(w);                w_pass[t_index,:,:,:] = w_sol[:,:,:];
            Θl_sol = getvalue(Θl);              Θl_pass[t_index,:,:,:] = Θl_sol[:,:,:];
            xl_sol = getvalue(xl);              xl_pass[t_index,:,:,:] = xl_sol[:,:,:];
            Θ_sol = getvalue(Θ);                Θ_pass[t_index,:,:] = Θ_sol[:,:];
            x_sol = getvalue(x);                x_pass[t_index,:,:] = x_sol[:,:];
            z_sol = getvalue(z);                z_pass[t_index,:,:,:,:] = z_sol[:,:,:,:];
            te_sol = getvalue(te);              te_pass[t_index,:,:] = te_sol[:,:];
            ts_sol = getvalue(ts);              ts_pass[t_index,:,:] = ts_sol[:,:];
            trt_sol = getvalue(trt);            trt_pass[t_index,:,:,:] = trt_sol[:,:,:];
            inv_sol = getvalue(inv);            inv_pass[t_index,:,:] = inv_sol[:,:];
            invo_sol = getvalue(invo);          invo_pass[t_index,:,:] = invo_sol[:,:];
            s_sol = getvalue(s);                s_pass[t_index,:,:] = s_sol[:,:];
            area_sol = getvalue(area);          area_pass[t_index,:,:] = area_sol[:,:];

            println("Output de Planner = ", x_sol)
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
=#
