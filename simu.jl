# x=============================================================================
# In case that this code is used to simulate another model different of
# monolith3.jl, the programmer should look at:
# - "Section 1": change the parameters and data of the problem
# - "Section 4": change the "transformation" funtion
# - "Section 5":
# x=============================================================================

tic()

using ResumableFunctions
using SimJulia
using Distributions

# ------------------------------------------------------------------------------
#                                 Section 1
#                         Data, Parameters and Model
# ------------------------------------------------------------------------------
N_simu = 1              # Number of Monte Carlo Simulations
N_products = 3
N_periods_opti = 1      # Optimization horizon
N_periods_simu = 10      # Simulation horizon (Should be greater than or equal to the Optimization horizon)
N_planner_decision = 3  # Number of periods (weeks) when the planner makes a decision
# TODO: Se debería crear un "Planner horizon" y un "Scheduler horizon" que
# indican el número de periodos que tienen en cuenta el planner y el scheduler

d_dem = Normal(14333.333,10631.595)     # Normal distribution for Demand generation

# Run the file with the Optimization model
include("monolith.jl")

# On the main code we define the following parameters because (1) they have
# uncertainty or (2) they allow communication between simulation agents:
mutable struct SCSimulationData
    Dem         # DEMAND FOR PRODUCT I AT THE END OF PERIOD T
    i_sim       # Index for the simulation number
    t_index     # Actual period (week) of simulation
    fail_time   # Array of dimension N_rsc*2
                # fail_time = [time when the next failure its going to happen,time of the failure]
    planner_constant    # This constant is used to know when does the planner make a decision

    R           # PRODUCTION RATES FOR PRODUCTS
    INVI        # INITIAL INVENTORY AT HAND
    Winit       # Binary variable to denote if product i was assigned to period t_index-1
    #=
    list        # Communication between planner/scheduler and operator
    fail_prod   # Failures in production process (operator agent): (1) week,
                # (2) slot, (3) product and (4) amount
    sells       # Expected sales of product i in period t_index
    backlogs    # Array that counts how many backlogs the process had: (1) week,
                # (2) product and (3) amount of backlog
    info        # Communication between planner and scheduler
    x_planner
    =#
end
function SCSimulationData()
    Dem = rand(d_dem,N_products,N_periods_opti); Dem = abs.(Dem)    # Initialization for the Demand generation
    i_sim = 0
    t_index = 0
    fail_time = [0,0]
    planner_constant = 0

    R = [800.0  900  1000 1000 1200]
    INVI = [0.0 for i in 1:N_products]
    Winit = [0 for i in 1:N_products]
    #=
    list = -1*ones(N_products,4)
    fail_prod = zeros(4,1)
    sells = -1*ones(N_products)
    backlogs = zeros(3,1)
    info = -1*ones(N_products)
    x_planner = -1*ones(N_products)
    =#

    #s = SCSimulationData(Dem,R,INVI,Winit,list,t_index,fail_prod,sells,backlogs,info,x_planner,fail_time,i_sim)
    s = SCSimulationData(Dem,i_sim,t_index,fail_time,planner_constant,R,INVI,Winit)
end

# ------------------------------------------------------------------------------
#                                 Section 2
#                        Main function for simulation
# ------------------------------------------------------------------------------
@resumable function start_sim(sim::Simulation,sc::SCSimulationData)
    # Set up the first failure time
    sc.fail_time = fail_machine(0)

    for t_ind in 1:N_periods_simu
        sc.t_index = t_ind

        println("\n")
        println("-------------------------------------- Week #$(sc.t_index) of Simulation #$(sc.i_sim) ----------------------------------------")

        client_process = @process client(sim,sc)
        @yield client_process

        if sc.t_index == 1
            planner_process = @process planner(sim,sc)
            @yield planner_process

            # In the first period the planner should take the decision (i.e. the
            # constant starts to count)
            sc.planner_constant = 1

        # This if statement guarantees that the planner only makes decisions
        # (i.e. solve optimization problems) every certain period of time
        elseif sc.t_index == sc.planner_constant*N_planner_decision+1
            planner_process = @process planner(sim,sc)
            @yield planner_process

            # Update of the constant to know when the planner is going to make a decision
            sc.planner_constant += 1
        else
            println("   THE SCHEDULER DID IT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        end

        #=
        operator_process = @process operator(sim,sc)
        @yield operator_process

        dispatch_process = @process dispatch(sim,sc)
        @yield dispatch_process
        =#
    end

    #= TODO:Descomentar esto para guardar los KPI de la simulacion
    final = size(sc.backlogs)
    println("\n")
    println("The process had $(final[2]-1) backlog(s) in total during the simulation")
    for ind in 2:final[2]
        println("   One in week $(round(sc.backlogs[1,ind],2)) of $(round(sc.backlogs[3,ind],2)) units of product $(round(sc.backlogs[2,ind],2))")
    end
    =#

    println("\n")
    println("  ___   _ __  __    _   _")
    println(" / __\\ | '_ ''_ '  | | | |")
    println("| (__  | | | | | | | |_| |")
    println(" \\___/ |_| |_| |_|  \\___/        Simulation #$(sc.i_sim) was completed")
end

# ------------------------------------------------------------------------------
#                                 Section 3
#                             Failure function
# This function is used to create a failure time for the process
# ------------------------------------------------------------------------------
function fail_machine(t_ini::Number)
    lambda = 168                    # Constant probability per hour to get a failure
    d_fail = Exponential(lambda)    # Exponential distribution
    t_fail = t_ini + rand(d_fail)   # Random failure time: time in which a failure will occur

    d_fail2 = Normal(2,0.5)         # Normal distribution
    t_fail2 = rand(d_fail2)         # Random failure time: time the failure will last

    println("\n")
    println("---------->Next failure will happen in $t_fail")

    (t_fail,t_fail2)
end

# ------------------------------------------------------------------------------
#                                 Section 4
#                               Client agent
# The "client" agent is responsible for generating the demand in each period
# ------------------------------------------------------------------------------
@resumable function client(env::Simulation,sc::SCSimulationData)
    tam = size(sc.Dem)
    for t in 1:tam[2]-1
        sc.Dem[:,t] = sc.Dem[:,t+1]
    end
    sc.Dem[:,end] = rand(d_dem,N_products)

    # None of the generated numbers should be negative
    sc.Dem = abs.(sc.Dem)

    println("\n")
    println("    ^__^               Client agent")
    println("    (oo)\\______       ")
    println("   (__)\\       )\\/\\ ")
    println("        ||---- |       ")
    println("        ||    ||       The demand of week $(sc.t_index) is: ")
    for i in 1:N_products
        println("                       $(round(sc.Dem[i,1],2)) units of $i")
    end
end

# ------------------------------------------------------------------------------
#                                 Section 5
#                               Planner agent
# ------------------------------------------------------------------------------
@resumable function planner(env::Simulation,sc::SCSimulationData)
    # TODO incluir todos los parametros necesarios para saber cuando es un planer y cuando es un scheduler
    #m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti,sc.x_planner,false)
    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti)

    tic()
    status = solve(m)
    m_time = toq()

    println("\n")
    println("   (\\ _ /)         Planner agent")
    println("   ( 'x' )         ")
    println("   c(\")(\")         Solve status was $status")
    println("                   Optimization problem was solved in $m_time sec")

    # "to_operator" function is used to "transform" the optimization solution
    # into a list of works that the operator should understand and carry out
    # TODO incluir esto ==== planner_operator(m,sc)

    # "to_scheduler" function is used to comucate the planner and the scheduler
    # TODO incluir esto ==== planner_scheduler(m,sc)
end

# ------------------------------------------------------------------------------
#                                Section NUMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
#                           Monte Carlo simlation
# ------------------------------------------------------------------------------
simu_time = [0.0]
for i in 1:N_simu
    tic()

    montecarlo = i;     srand(montecarlo)
    println("\n")
    println("Seed for Monte Carlo simulation = $montecarlo")

    sc = SCSimulationData()
    sim = Simulation()
    @process start_sim(sim,sc)

    sc.i_sim = i
    run(sim)

    tim = convert(Float64,toq())
    simu_time = push!(simu_time,tim)

    println("\n")
    println("Solution time for simulation #$(sc.i_sim) = $tim")
end

println("\n")
println("                _                       _       _             _   _   _")
println("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
println(" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
println("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
println(" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)   All simulations were completed")

# ------------------------------------------------------------------------------
#                                    End
# ------------------------------------------------------------------------------

# Creo que: si existe algun problema en el proceso (no alcanzo el tiempo o hubo
# una falla en una maquina), el proceso deberia producir hasta donde pueda.
# Por ejemplo, si no se tiene el tiempo suficiente,entonces la actividad no se
# lleva a cabo para nada, pero creo que se deberia llevar a cabo hasta donde sea
# posible

# Debo encontrar la manera de crear archivos .txt para guardar los resultados
# de las simulaciones

# tener en cuenta el Profit como una variable de respuesta de la simulacion

# Contar el numero de fallas (no como si fuera una variable de respuesta, sino
# para poder analizar mejor los resultados)

#https://www.google.com/search?q=how+to+generate+data+for+monte+carlo+simulation&rlz=1C1NHXL_esCO702CO702&oq=how+to+generate+data+for+monte+carlo+simulation&aqs=chrome..69i57.56607j0j7&sourceid=chrome&ie=UTF-8
#https://www.researchgate.net/post/How_do_I_produce_samples_for_conducting_Monte_Carlo_experiment_for_regression_Analysis
#https://www.investopedia.com/articles/investing/093015/create-monte-carlo-simulation-using-excel.asp

# Hay forma de especificar la hoja en el archivo .csv en la que se desea
# escribir? Así se podría tener distintas hojas para guardar distintos tipos de
# información como: Una hoja de los parametros generados aleatoriamente, otra
# con los resultados de KPI, otra con la información de qué ocurrió durante la
# simu, etc.
