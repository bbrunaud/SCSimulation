tic()

using ResumableFunctions
using SimJulia
using JuMP
using Cbc
using Distributions

N_products = 5
N_periods = 4

include("monolith2.jl")

@resumable function start_sim(sim::Simulation,t_ind::Number,w_pass::Array,Θl_pass::Array,ts_pass::Array,te_pass::Array,xl_pass::Array,s_pass::Array,inv_pass::Array,invo_pass::Array)
    println("\n")
    println("   _[_]_   ")
    println("   (o,o)       Simulation of Week #$t_ind started!!!")
    println("   ( : )   ")
    println("   ( : )   ")

    cond = true
    boo = false
    @yield timeout(sim,0.0+168.0*(t_ind-1))

    for t in t_ind:N_periods
        if cond == true
            for l in 1:N_products
                if cond == true
                    println("Slot $l:")
                    for i in 1:N_products
                        #println("w_pass[$t,$i,$l,$t_ind] = ",w_pass[t_ind,i,l,t])
                        if w_pass[t_ind,i,l,t] > 0.9
                            tot_t = te_pass[t_ind,l,t]-ts_pass[t_ind,l,t] #tot_t: tiempo total del producto i en slot l de week t
                            prod_t = Θl_pass[t_ind,i,l,t] #prod_t: tiempo de produccion de i en slot l de week t
                            trans_t = tot_t-prod_t #trans_t: tiempo de transicion despues de la produccion de i en slot l de week t

                            println("process time = ",round(now(sim),3))

                            println("Product $i: the theoretical total time was of ",round(tot_t,3)," hours")
                            println("Product $i: the theoretical production time was of ",round(prod_t,3)," hours")
                            println("Product $i: the theoretical transition time was of ",round(trans_t,3)," hours")

                            #incertidumbre en el tiempo de transicion
                            if trans_t >= 0.5 #Es 0.5 porque no cambia el tiempo de trans si este es igual a 0 y 0.5 es el minimo de τ
                                #srand(12)
                                d_trans_t = Normal(trans_t,0.2)     #Distribucion normal para el tiempo de transicion
                                trans_t = rand(d_trans_t)
                                println("Product $i: took ",round(trans_t,3)," hours of transition")
                            else
                                println("Product $i: did not have any transition time")
                            end

                            #incertidumbre en el rendimiento
                            #=R_pass = R[i] #R_pass es el R original

                            d_R = Normal(R[i],50) #Distribucion normal para incertidumbre del rendimiento R[i]
                            R[i] = rand(d_R)

                            prod_t = xl_pass[t_ind,i,l,t]/R[i]
                            println("Product $i: the real production time was of ",round(prod_t,3)," hours")

                            R[i] = R_pass=#

                            tot_t = prod_t+trans_t

                            @yield timeout(sim,tot_t)

                            println("process time = ",round(now(sim),3))

                            if round(now(sim),1) > 168.0*t_ind
                                println("\n")
                                println("Se acabo la semana!!! El tiempo limite era de ",168.0*t_ind)
                                println("pero el ultimo trabajo iba a durar hasta = ",round(now(sim),1))

                                delay_t = now(sim)-168.0*t_ind
                                println("tiene un delay en esta semana de = ",round(delay_t,3)," horas")
                                t_real = tot_t-delay_t #tiempo real del trabajo que se paso de tiempo
                                println("t_real = ",t_real)

                                @yield timeout(sim,-delay_t)
                                println("process time = ",round(now(sim),3))

                                #Aca se actualizan las variables para el problema de opti de la prox week
                                boo = true #boo var booleana que indica que si se paso el tiempo y que algun producto se tiene que fijar en el futuro
                                i_boo = i #i_boo es el producto que se paso
                                t_boo = t #t_boo es la semana en donde se tiene que producir i_Boo en el lote 1
                                ts_boo = 168.0*t_ind #ts_boo es el tiempo de start de ese primer lote
                                te_boo = delay_t #te_boo es el tiempo de end de ese primer lote

                                #=
                                w_pass[t_ind,:,1,t] = 0
                                w_pass[t_ind,i,1,t] = 1
                                ts_pass[t_ind,1,t] = 168.0*t_ind
                                te_pass[t_ind,1,t] = delay_t
                                xl_pass[t_ind,i,l,t] = R[i]*t_real

                                x_prod = R[i]*t_real #x_prod = lo que se produjo de i en el ultimo tiempo de simulacion

                                if t_ind > 1
                                    inv_pass[t_ind,i,t-1] = invo_pass[t_ind,i,t-1] + x_pass[i,t_index]
                                else
                                   inv_pass[t_index,i,t_index] = INVI[i] + x_pass[t_index,i,t_index]
                                end
                                invo_pass[t_ind,i,t-1] = inv_pass[t_index,i,t_index] - s_pass[t_index,i,t_index]
                                invo_pass[t_ind,i,t-1] = invo_pass[t_ind,i,t-1]
                                =#

                                cond = false
                            elseif round(now(sim),1) == 168.0*t_ind
                                println("\n")
                                println("La semana finalizo correctamente!!! en ",round(168.0*t_ind,3)," horas")
                                cond = false
                            else
                                #Este es el caso en el que es menor
                            end


                        end
                    end
                end
            end
        end
    end
    if t_ind <= N_periods-1
        principal(t_ind+1)
    end
    println("La semana finalizo correctamente!!! en ",round(now(sim),1)," horas")
    #return (boo,i_boo,t_boo,ts_boo,te_boo)
end

#1. Se crean los parametros iniciales: la demanda y el inventario inicial
srand(123); d = Normal(14333.33333, 10631.595); Dem = rand(d, N_products, N_periods)
Dem = [0.0        10000        20000        0
    15000        10000        5000        15000
    20000        30000        40000       20000
    20000        10000        3000        20000
    20000        10000        2000        20000]

INVI = [0 for i in 1:5]

#2. Se crean los vectores que almacenaran la informacion de la opti y la simu
w_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
Θl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
xl_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
Θ_pass = -1*ones(Float64, N_periods, N_products, N_periods)
x_pass = -1*ones(Float64, N_periods, N_products, N_periods)
z_pass = -1*ones(Float64, N_periods, N_products, N_products, N_products, N_periods)
te_pass = -1*ones(Float64, N_periods, N_products, N_periods)
ts_pass = -1*ones(Float64, N_periods, N_products, N_periods)
trt_pass = -1*ones(Float64, N_periods, N_products, N_products, N_periods)
inv_pass = -1*ones(Float64, N_periods, N_products, N_periods)
invo_pass = -1*ones(Float64, N_periods, N_products, N_periods)
s_pass = -1*ones(Float64, N_periods, N_products, N_periods)
area_pass = -1*ones(Float64, N_periods, N_products, N_periods)

#3. Se hace un for que recorre cada semana
function principal(t_index)
#for t_index in 1:N_periods
    println("\n")
    println("                 ^__^")
    println("                 (oo)\\______")
    println("   Well Done    (__)\\       )\\/\\")
    println("                     ||---- |")
    println("                     ||    ||          Week #$t_index started!")

    #4. Se resuelve el problema de opti (Trabajo del Planner/Scheduler)
    if t_index == 1
        println("\n")
        println("Dem = ",Dem)

        m = monolith(Dem,N_products,N_periods)

         tic()
         status = solve(m)
         m_time = toc()

         println("\n")
         println("   (\\ _ /)      Solve status was $status")
         println("   ( 'x' )        ")
         println("   c(\")(\")      Problem was solved in $m_time sec")

         w = getindex(m, :w);                w_sol = getvalue(w);                w_pass[1,:,:,:] = w_sol[:,:,:];
         Θl = getindex(m, :Θl);              Θl_sol = getvalue(Θl);              Θl_pass[1,:,:,:] = Θl_sol[:,:,:];
         xl = getindex(m, :xl);              xl_sol = getvalue(xl);              xl_pass[1,:,:,:] = xl_sol[:,:,:];
         Θ = getindex(m, :Θ);                Θ_sol = getvalue(Θ);                Θ_pass[1,:,:] = Θ_sol[:,:];
         x = getindex(m, :x);                x_sol = getvalue(x);                x_pass[1,:,:] = x_sol[:,:];
         z = getindex(m, :z);                z_sol = getvalue(z);                z_pass[1,:,:,:,:] = z_sol[:,:,:,:];
         ts = getindex(m, :ts);              ts_sol = getvalue(ts);              ts_pass[1,:,:] = ts_sol[:,:];
         te = getindex(m, :te);              te_sol = getvalue(te);              te_pass[1,:,:] = te_sol[:,:];
         trt = getindex(m, :trt);            trt_sol = getvalue(trt);            trt_pass[1,:,:,:] = trt_sol[:,:,:];
         inv = getindex(m, :inv);            inv_sol = getvalue(inv);            inv_pass[1,:,:] = inv_sol[:,:];
         invo = getindex(m, :invo);          invo_sol = getvalue(invo);          invo_pass[1,:,:] = invo_sol[:,:];
         s = getindex(m, :s);                s_sol = getvalue(s);                s_pass[1,:,:] = s_sol[:,:];
         area = getindex(m, :area);          area_sol = getvalue(area);          area_pass[1,:,:] = area_sol[:,:];
     else
         Dem[:,t_index] = Dem[:,t_index] + 3*randn()
         println("\n")
         println("Dem = ",Dem)

         m = monolith(Dem,N_products,N_periods)

         w = getindex(m, :w);
         Θl = getindex(m, :Θl);
         xl = getindex(m, :xl);
         Θ = getindex(m, :Θ);
         x = getindex(m, :x);
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

         #if boo == true
            #setlowerbound.(w[:,1,t_boo],0);  setupperbound.(w[:,1,t_boo],0);
            #setlowerbound.(w[i_bool,1,t_boo],1); setupperbound.(w[i_bool,1,t_boo],1);
            #setlowerbound.(ts[1,t_boo],ts_boo);  setupperbound.(ts[1,t_boo],ts_boo);
            #setlowerbound.(te[1,t_boo],te_boo);  setupperbound.(te[1,t_boo],te_boo);
         #end

         tic()
         status = solve(m)
         m_time = toc()

         println("\n")
         println("   (\\ _ /)      Solve status was $status")
         println("   ( 'x' )        ")
         println("   c(\")(\")      Problem was solved in $m_time sec")

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
     end

     #=if isodd(t_index) == true
        #Aca se resuelve el problema y se guardan las variables comun y corriente
    else
        #Aca se fijan las variables del planer setlowerbound.(x[:,t_index],x_pass[t_index-1,:,t_index]);
    end=#

    #6. Se realiza la simulacion para la semana t_index
    sim = Simulation()
    @process start_sim(sim,t_index,w_pass[:,:,:,:],Θl_pass[:,:,:,:],ts_pass[:,:,:],te_pass[:,:,:],xl_pass[:,:,:,:],s_pass[:,:,:],inv_pass[:,:,:],invo_pass[:,:,:])
    run(sim)

end

t_index = 1
boo = false
i_boo = -1
t_boo = -1
ts_boo = -1
te_boo = -1

#principal(t_index)

Winit = [0 0 0 0 1]
m = monolith(Dem,N_products,N_periods,Winit)
solve(m)
w = getindex(m, :w);                w_sol = getvalue(w);
println("w = ",w_sol[:,1,1])

println("\n")
println("                _                       _       _             _   _   _")
println("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")
println("\n")

toc()

#println("\n")
#println(" /\\__/\\")
#println("(=^.^=)")
#println(" (\")(\")_/")
