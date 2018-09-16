using ResumableFunctions
using SimJulia
using JuMP
using Cbc

tic()

N = 4

include("rafa.jl")

@resumable function Customer(sim::Simulation)
     #Dem=rand()
     Dem=1.333333333333
end

@resumable function Planner(sim::Simulation, Dem::Float64, m::Model)
    y = getindex(m, :y)
    x = getindex(m, :x)

    status = solve(m)

    x_sol = getvalue(x) #x_sol = Solucion de x
    y_sol = getvalue(y) #y_sol = Solucion de y

    @show x_sol
    @show y_sol

    println("\n")
    println("                 ^__^")
    println("                 (oo)\\______")
    println("   Well Done    (__)\\       )\\/\\")
    println("                     ||---- |")
    println("                     ||    ||")
    println("\n");

    (m, x, y, x_sol, y_sol)

    #y = getindex(m,y)

    #@show status
    #@show getvalue(y)
    #@show getvalue(x)

end

@resumable function start_sim(sim::Simulation)
    Customer_process = @process Customer(sim)
    Dem = @yield Customer_process
    println("Demand = ", Dem)

    m = rafa(Dem)

    #while true
    for i in 1:N
        #@yield timeout(sim, N/4)
        #@show now(sim)
        @show i

        Plan_process = @process Planner(sim, Dem, m)
        (m, x, y, x_sol, y_sol) = @yield Plan_process
        #println("Output de Planner = ", (m, x, y, x_sol, y_sol))

#Hay que poner condicionales que hagan lo siguiente:
#1. Para cada tiempo se deben fijar las variables del tiempo anterior, asi no se
#   mueven variables "del pasado" durante la optimizacion
#2. En cada semana impar las variables del planer deben quedar fijas, pues el
#   planner solo puede mover las variables cada 2 semanas

        if isodd(i) == true
            if i == 1
                println("Inpar con  i = ", i)

                setlowerbound(y[i],y_sol[i]-2)
                setupperbound(y[i],y_sol[i]-2)
            else
                println("Inpar con  i = ", i)

                setlowerbound(y[i-1],y_sol[i]-2)
                setupperbound(y[i-1],y_sol[i]-2)
            end
        end

        #setupperbound(y,now(sim))
        #setlowerbound(y,now(sim))

    end
end

sim = Simulation()
@process start_sim(sim)
run(sim)

println("                  _                        _       _             _   _   _")
println("  ____    ____   | |   ____    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / __ \\  / __ \\  | |  / __ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (__   | (__) | | | | (__) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\____/  \\____/  |_|  \\____/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")

toc()
