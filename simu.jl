# x=============================================================================
# In case that this code is used to simulate another model different of
# monolith.jl, the programmer should look at:
# x=============================================================================

tic()

using ResumableFunctions
using SimJulia
using Distributions
using DataFrames
using CSV

# ------------------------------------------------------------------------------
#                                 Section 1
#                         Data, Parameters and Model
# ------------------------------------------------------------------------------
N_simu = 1              # Number of Monte Carlo Simulations
N_rsc = 1               # Number of resources (e.g. machines, reactors, etc.)
N_sites = 1             # Number of sites of the company
N_products = 5          # Number of products
N_slots = N_products    # Number of products
N_periods_opti = 3      # Optimization horizon
N_periods_simu = 5      # Simulation horizon (Should be greater than or equal to the Optimization horizon)
N_planner_decision = 3  # Number of periods (weeks) when the planner makes a decision
# TODO: Se debería crear un "Planner horizon" y un "Scheduler horizon" que
# indican el número de periodos que tienen en cuenta el planner y el scheduler.
# En este momento solo se tiene en cuenta N_periods_opti para "ambos" agentes

d_dem = Normal(14333.333,10631.595)     # Normal distribution for Demand generation

# Run the file with the Optimization model
include("monolith.jl")

# Data frame to store the results
df = DataFrame(Code_Line=[])
df_backlogs = DataFrame(week=[],product=[],amount=[])

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
    Orders      # List of orders from the planner or scheduler to the operator
    sells       # Expected sales of product i in period t_index
    backlogs    # Array that counts how many backlogs the process had: (1) week,
                # (2) product and (3) amount of backlog
    #=
    fail_prod   # Failures in production process (operator agent): (1) week,
                # (2) slot, (3) product and (4) amount
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
    Orders = -1*ones(N_sites,N_rsc,N_slots,5)
    sells = -1*ones(N_products)
    backlogs = zeros(3,1)
    #=
    fail_prod = zeros(4,1)
    =#
    s = SCSimulationData(Dem,i_sim,t_index,fail_time,planner_constant,R,INVI,Winit,Orders,sells,backlogs)
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

        line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        line = ("-------------------------------------- Week #$(sc.t_index) of Simulation #$(sc.i_sim) ----------------------------------------"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

        client_process = @process client(sim,sc)
        @yield client_process

        # This if statement is used to know if it is the planner's turn or the
        # scheduler's turn
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

            # Update of the constant to know when the planner is going to make a
            # decision
            sc.planner_constant += 1
        else
            scheduler_process = @process scheduler(sim,sc)
            @yield scheduler_process
        end

        rsc = []
        for i in 1:N_rsc
            push!(rsc,Resource(sim, 1))
        end

        line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        line = ("     @..@          Operator agent"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        line = ("    (----)         "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        line = ("   ( >__< )        "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        line = ("    ^^  ^^         "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        for s in 1:N_sites
            for u in 1:N_rsc
                for l in 1:N_slots
                    if now(sim)+sc.Orders[s,u,l,3]+sc.Orders[s,u,l,4] > 168*sc.t_index
                        line = ("The remaining time of week $(sc.t_index) is not enough to complete the task in slot $l"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
                    end
                    operator_process = @process operator(sim,sc,rsc[u],s,u,l,sc.Orders[s,u,l,1],sc.Orders[s,u,l,2],sc.Orders[s,u,l,3],sc.Orders[s,u,l,4],sc.Orders[s,u,l,5])
                    @yield operator_process
                end
            end
        end

        dispatch_process = @process dispatch(sim,sc)
        @yield dispatch_process
    end

    #= TODO:Descomentar esto para guardar los KPI de la simulacion
    final = size(sc.backlogs)
    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("The process had $(final[2]-1) backlog(s) in total during the simulation"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    for ind in 2:final[2]
        line = ("   One in week $(round(sc.backlogs[1,ind],2)) of $(round(sc.backlogs[3,ind],2)) units of product $(round(sc.backlogs[2,ind],2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    end
    =#

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("  ___   _ __  __    _   _"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = (" / __\\ | '_ ''_ '  | | | |"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("| (__  | | | | | | | |_| |"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = (" \\___/ |_| |_| |_|  \\___/        Simulation #$(sc.i_sim) was completed"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
end

# ------------------------------------------------------------------------------
#                                 Section 3
#                          Not Resumable Functions
# ------------------------------------------------------------------------------
#                                Section 3.1
#                             Failure function
# This function is used to create a failure time for the process
# ------------------------------------------------------------------------------
function fail_machine(t_ini::Number)
    lambda = 168                    # Constant probability per hour to get a failure
    d_fail = Exponential(lambda)    # Exponential distribution
    t_fail = t_ini + rand(d_fail)   # Random failure time: time in which a failure will occur

    d_fail2 = Normal(2,0.5)         # Normal distribution
    t_fail2 = rand(d_fail2)         # Random failure time: time the failure will last

    line = ("---------> Next failure will happen in $(round(t_fail,2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    (t_fail,t_fail2)
end

# ------------------------------------------------------------------------------
#                                Section 3.2
#                           Communication function
# This function transforms the optimization model solution into a list of works
# for the operator (i.e. this should be the only function that must be changed
# if the optimization model changes). Also, this function communicate the
# expected sells for the Dispatch agent
# ------------------------------------------------------------------------------
function Orders_function(m::JuMP.Model,sc::SCSimulationData)
    # TODO: Esto se debe actualizar con respecto al modelo de grafos
    w = getindex(m,:w);         w_sol = getvalue(w)         # w = binary variable to denote if product i is assigned to slot l of period t
    Θl = getindex(m,:Θl);       Θl_sol = getvalue(Θl)       # Θl = production time of product i in slot l of period t
    xl = getindex(m,:xl);       xl_sol = getvalue(xl)       # xl = amount produced of product i in slot l of period t
    ts = getindex(m,:ts);       ts_sol = getvalue(ts)       # ts = start time of slot l in period t
    te = getindex(m,:te);       te_sol = getvalue(te)       # te = end time of slot l in period t
    invo = getindex(m,:invo);   invo_sol = getvalue(invo)   # invo = final inventory of product i at time t after demands are satisfied
    inv = getindex(m,:inv);     inv_sol = getvalue(inv)     # inv = inventory level of product i at the end of time period t
    s = getindex(m,:s);         s_sol = getvalue(s)         # s = sales of product i in period t

    # list is used by the operator agent
    for si in 1:N_sites
        for rsc in 1:N_rsc
            for l in 1:N_slots
                for i in 1:N_products
                    if w_sol[i,l,1] > 0.9
                        prod = i                        # i: product assigned to slot l in period t_index
                        ini_t = ts_sol[l,1]             # s_t: start time of slot l in period t_index
                        tot_t = te_sol[l,1]-ts_sol[l,1] # tot_t: total time of product i in period t_index
                        prod_t = Θl_sol[i,l,1]          # prod_t: production time of product i in period t_index
                        trans_t = tot_t - prod_t        # trans_t: transition time of product i in period t_index
                        amount = xl_sol[i,l,1]          # amount: amount produced of product i in period t

                        sc.Orders[si,rsc,l,:] = [prod,ini_t,prod_t,trans_t,amount]
                    end
                end
            end
        end
    end

    # sells is used by the dispatch agent
    sc.sells[:] = s_sol[:,1]
end

# ------------------------------------------------------------------------------
#                                 Section 4
#                               Client agent
# The "client" agent is responsible for generating the demand in each period
# ------------------------------------------------------------------------------
@resumable function client(sim::Simulation,sc::SCSimulationData)
    tam = size(sc.Dem)
    for t in 1:tam[2]-1
        sc.Dem[:,t] = sc.Dem[:,t+1]
    end
    sc.Dem[:,end] = rand(d_dem,N_products)

    # None of the generated numbers should be negative
    sc.Dem = abs.(sc.Dem)

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("    ^__^               Client agent"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("    (oo)\\______       "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   (__)\\       )\\/\\ "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("        ||---- |       "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("        ||    ||       The demand of week $(sc.t_index) is: "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    for i in 1:N_products
        line = ("                       $(round(sc.Dem[i,1],2)) units of $i"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    end
end

# ------------------------------------------------------------------------------
#                                 Section 5
#                               Planner agent
# ------------------------------------------------------------------------------
@resumable function planner(sim::Simulation,sc::SCSimulationData)
    # TODO incluir todos los parametros necesarios para saber cuando es un planer y cuando es un scheduler
    #m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti,sc.x_planner,false)
    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti)

    tic()
    status = solve(m)
    m_time = toq()

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   (\\ _ /)         Planner agent"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   ( 'x' )         "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   c(\")(\")         Solve status was $status"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("                   Optimization problem was solved in $m_time sec"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    # "Orders_function" is used to "transform" the optimization solution into a
    # list of works that the operator have to carry out
    Orders_function(m,sc)

    # "to_scheduler" function is used to comucate the planner and the scheduler
    # TODO incluir esto ==== planner_scheduler(m,sc)
end

# ------------------------------------------------------------------------------
#                                 Section 6
#                               Scheduler agent
# ------------------------------------------------------------------------------
@resumable function scheduler(sim::Simulation,sc::SCSimulationData)
    #for i in 1:N_products
    #    println("   $(round(sc.x_planner[i],2)) units of $i")
    #end
    # TODO: se debe descomentar lo anterior para diferenciar lo que hace el
    # scheduler de lo que hace el planner

    # TODO incluir todos los parametros necesarios para saber cuando es un planer y cuando es un scheduler
    #m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti,sc.x_planner,false)
    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods_opti)

    tic()
    status = solve(m)
    m_time = toq()

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   _[_]_       Scheduler agent"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   (o,o)       "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   ( : )       "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   ( : )       Solve status was $status"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("               Optimization problem was solved in $m_time sec"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    Orders_function(m,sc)

    # TODO = revisar cuales seran las nuevas variables de comunicacion como las slack
    #planner_operator(m,sc)
    #slack_n = getindex(m,:slack_n); slack_n_sol = getvalue(slack_n)
    #slack_p = getindex(m,:slack_p); slack_p_sol = getvalue(slack_p)
    #cond = true
    #for i in 1:N_products
    #    if slack_n_sol[i] > 0 || slack_p_sol[i] > 0
    #        line = ("   The Scheduler did not fully comply with the Planner's decisions for Product $i production"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    #        cond = false
    #    end
    #end
    #if cond == true
    #    line = ("   The Scheduler fully complied with the Planner's decisions for all products"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    #end
end

# ------------------------------------------------------------------------------
#                                 Section 7
#                              Operator agent
# Input parameters: s=site, u=unit, l=slot, p=product, ini_t=initial time of
#                   product p in slot l, prod_t=production time and
#                   trans_t=transition time
# ------------------------------------------------------------------------------
@resumable function operator(sim::Simulation,sc::SCSimulationData,rsc::Resource,s::Number,u::Number,l::Number,p::Number,ini_t::Number,prod_t::Number,trans_t::Number,amount::Number)
    @yield request(rsc)
    line = ("Unit $u started to work with product $p (slot $l of week $(sc.t_index)) at $(round(now(sim),2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    # Uncertainty of production rate: Normal distribution. The uncertainty
    # should only be applied if there is any production time
    if prod_t > 0
        d_R = Normal(sc.R[convert(Int64,p)]-45,50)
        R_alea = rand(d_R)
        prod_t_alea = amount/R_alea
        line = ("   The theoretical production time was of $(round(prod_t,2)) hr, but it was of $(round(prod_t_alea,2)) hr"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        prod_t = prod_t_alea
        sc.INVI[convert(Int64,p)] += prod_t*R_alea
    else
        line = ("   Product $p was not produced in slot $l of week $(sc.t_index) (The inventory was not updated)"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    end
    @yield timeout(sim,prod_t)

    # Uncertainty of transition time: Normal distribution
    # The uncertainty should only be applied if there is any transition time
    # trans_t >= 0.5 is because that is the minimal transition time in the model
    if trans_t >= 0.5
        d_trans_t = Normal(trans_t+0.1,0.2)
        trans_t_alea = rand(d_trans_t)
        line = ("   The theoretical transition time was of $(round(trans_t,2)) hr, but it was of $(round(trans_t_alea,2)) hr"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        trans_t = trans_t_alea
    else
        line = ("   Product $p did not have any transition time in slot $l"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    end
    @yield timeout(sim,trans_t)

    # Uncertainty of failure: If there was a failure, then the a failure time is
    # going to be added to the total time
    if now(sim) >= sc.fail_time[1]
        # The process had a failure
        line = ("---------> There was a failure of $(round(sc.fail_time[2],2)) hours in slot $l of week $(sc.t_index) at $(round(sc.fail_time[1],2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        @yield timeout(sim,sc.fail_time[2])

        # Set up the new failure time
        sc.fail_time = fail_machine(sc.fail_time[1])
    end

    line = ("       Product $p is leaving unit $u at $(round(now(sim),2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    @yield release(rsc)
end

# ---------------------------------------------------------------------------- #
#                                 Section 8                                    #
#                               Dispatch agent                                 #
# ---------------------------------------------------------------------------- #
@resumable function dispatch(sim::Simulation,sc::SCSimulationData)
    backlog = zeros(3,1)

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("    /\\_/\\        "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   (=^.^=)         "); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("   (\")_(\")_/     Dispatch agent"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    #TODO Hacer que el dispatch sea el agente que genere los KPI
    sc.INVI -= sc.sells

    for i in 1:N_products
        #if round(sc.INVI[i]-sc.sells[i],2) < 0
        if round(sc.INVI[i],2) < 0
            backlog[1,1] = sc.t_index
            backlog[2,1] = i
            backlog[3,1] = -round(sc.INVI[i],2)

            line = ("   There was a backlog of product $i in week $(sc.t_index) of $(round(-sc.INVI[i],2)) units"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
            sc.backlogs = hcat(sc.backlogs,backlog); push!(df_backlogs,sc.t_index,i,round(-sc.INVI[i],2)); CSV.write("KPI1.csv",df_backlogs);
        else
            line = ("   No backlog of product $i in week $(sc.t_index)"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
        end
    end
end

# ------------------------------------------------------------------------------
#                                Section NUMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
#                           Monte Carlo simlation
# ------------------------------------------------------------------------------
simu_time = [0.0]
for i in 1:N_simu
    tic()

    # The seed parameter is used to initialize the pseudorandom number generator
    seed = i;     srand(seed)
    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("Seed for Monte Carlo simulation = $seed"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

    sc = SCSimulationData() # This struct is used to communicate the resumable functions between themselves
    sim = Simulation()
    rsc = []                # The Resource TODO Completar info: para qué sirven los resources?
    for i in 1:N_rsc
        push!(rsc,Resource(sim, 1))
    end

    @process start_sim(sim,sc)

    sc.i_sim = i
    run(sim)

    tim = convert(Float64,toq())
    simu_time = push!(simu_time,tim)

    line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
    line = ("Solution time for simulation #$(sc.i_sim) = $(round(tim,2))"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
end

line = ("\n"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = ("                _                       _       _             _   _   _"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = ("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = (" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = ("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = (" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)   All simulations were completed"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);
line = ("                                                                           Total simulation time = $(round(sum(simu_time),2)) sec = $(round(sum(simu_time)/60,2)) min"); println(line); push!(df,[line]); CSV.write("tabla.csv",df);

println(df)
println(df_backlogs)

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

# El modelo de optimizacion debe ser aprueba de errores, es decir que nunca
# puede dar infactible
