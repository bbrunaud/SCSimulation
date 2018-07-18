# x=============================================================================
# In case that this is used to simulate another model different of monolith3.jl,
# the programmer should look at:
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
N_weeks = 1
N_products = 3
N_periods = 4*N_weeks

# Optimization model
include("monolith3.jl")

srand(123)
# On the main code we define the following parameters because (1) they have
# uncertainty or (2) they allow communication between simulation agents:
mutable struct SCSimulationData
    Dem         # DEMAND FOR PRODUCT I AT THE END OF PERIOD T
    R           # PRODUCTION RATES FOR PRODUCTS
    INVI        # INITIAL INVENTORY AT HAND
    Winit       # Binary variable to denote if product i was assigned to period t_index-1
    list        # Communication between planner/scheduler and operator
    t_index     # Actual period (week) of simulation
    fail_prod   # Failures in production process (operator agent): (1) week,
                # (2) slot, (3) product and (4) amount
    sells       # Expected sales of product i in period t_index
    backlogs    # Array that counts how many backlogs the process had: (1) week,
                # (2) product and (3) amount of backlog
    info        # Communication between planner and scheduler
    x_planner
    fail_time   # Falla de maquina
end
function SCSimulationData()
    #Dem = [0.0          10000        20000        0
    #        15000        10000        5000        15000
    #        20000        30000        40000       20000
    #        20000        10000        3000        20000
    #        20000        10000        2000        20000]
    d_dem = Normal(14333.33333,10631.595);  Dem = rand(d_dem,N_products,N_periods)
    R = [800.0  900  1000 1000 1200]
    INVI = [0.0 for i in 1:N_products]
    Winit = [0 for i in 1:N_products]
    list = -1*ones(N_products,4)
    t_index = 0
    fail_prod = zeros(4,1)
    sells = -1*ones(N_products)
    backlogs = zeros(3,1)
    info = -1*ones(N_products)
    x_planner = -1*ones(N_products)
    fail_time = [0,0]

    s = SCSimulationData(Dem,R,INVI,Winit,list,t_index,fail_prod,sells,backlogs,info,x_planner,fail_time)
end

# ------------------------------------------------------------------------------
#                                 Section 2
#                               Client agent
# The "client" agent is responsible for generating the demand in each period
# ------------------------------------------------------------------------------
@resumable function client(env::Simulation,sc::SCSimulationData)
    d_dem = Normal(14333.33333,10631.595)
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

    println("\n")

    println("    ^__^               Client agent")
    println("    (oo)\\______       ")
    println("   (__)\\       )\\/\\ ")
    println("        ||---- |       ")
    println("        ||    ||       The demand of week $(sc.t_index) is: ")
    for i in 1:N_products
        println("                       $(round(sc.Dem[i,sc.t_index],2)) units of $i")
    end
end

# ------------------------------------------------------------------------------
#                                Section 3.1
#                               Planner agent
# The "Planner" agent is responsible for optimizing the model every two weeks
# ------------------------------------------------------------------------------
@resumable function planner(env::Simulation,sc::SCSimulationData)
    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods,sc.x_planner,false)
    status = solve(m)

    tic()
    status = solve(m)
    m_time = toc()

    println("\n")
    println("   (\\ _ /)       Planner agent")
    println("   ( 'x' )         ")
    println("   c(\")(\")     Solve status was $status")
    println("   Optimization problem was solved in $m_time sec")

    # "to_operator" function is used to "transform" the optimization solution
    # into a list of works that the operator should understand and carry out
    planner_operator(m,sc)

    # "to_scheduler" function is used to comucate the planner and the scheduler
    planner_scheduler(m,sc)

    #w = getindex(m,:w);     w_sol = getvalue(w);
    #x = getindex(m,:x);     x_sol = getvalue(x);
    #Θl = getindex(m,:Θl);   Θl_sol = getvalue(Θl);
    #println("\n")
    #println("w_sol = $(w_sol[:,:,2])")
    #println("Θl_sol = $(Θl_sol[:,:,2])")
    #println("x_sol = $(x_sol[:,2])")
end

# ------------------------------------------------------------------------------
#                                Section 3.2
#                               Scheduler agent
# ------------------------------------------------------------------------------
@resumable function scheduler(env::Simulation,sc::SCSimulationData)
    println("\n")
    println("   _[_]_   ")
    println("   (o,o)   ")
    println("   ( : )   ")
    println("   ( : )   Communication planner/scheduler")

    println("The planner says: in week $(sc.t_index) the plant must produce:")
    for i in 1:N_products
        println("   $(round(sc.x_planner[i],2)) units of $i")
    end

    m = monolith(sc.Dem,sc.R,sc.INVI,sc.Winit,N_products,N_periods,sc.x_planner,true)
    status = solve(m)

    tic()
    status = solve(m)
    m_time = toc()

    println("\n")
    println("   (\\ _ /)       Scheduler agent")
    println("   ( 'x' )         ")
    println("   c(\")(\")     Solve status was $status")
    println("   Optimization problem was solved in $m_time sec")

    planner_operator(m,sc)

    #slack_n = getindex(m,:slack_n); slack_n_sol = getvalue(slack_n)
    #slack_p = getindex(m,:slack_p); slack_p_sol = getvalue(slack_p)
    #println("slack_p_sol = $(slack_p_sol)")
    #println("slack_n_sol = $(slack_n_sol)")

end

# ------------------------------------------------------------------------------
#                                Section 4.1
#                           Communication function
# This function transforms the optimization model solution into a list of works
# for the operator (i.e. this should be the only function that must be changed
# if the optimization model changes). Also, this function communicate the
# expected sells for the Dispatch agent
# ------------------------------------------------------------------------------
function planner_operator(m::JuMP.Model,sc::SCSimulationData)
    w = getindex(m,:w);         w_sol = getvalue(w)         # w = binary variable to denote if product i is assigned to slot l of period t
    Θl = getindex(m,:Θl);       Θl_sol = getvalue(Θl)       # Θl = production time of product i in slot l of period t
    xl = getindex(m,:xl);       xl_sol = getvalue(xl)       # xl = amount produced of product i in slot l of period t
    ts = getindex(m,:ts);       ts_sol = getvalue(ts)       # ts = start time of slot l in period t
    te = getindex(m,:te);       te_sol = getvalue(te)       # te = end time of slot l in period t
    invo = getindex(m,:invo);   invo_sol = getvalue(invo)   # invo = final inventory of product i at time t after demands are satisfied
    inv = getindex(m,:inv);     inv_sol = getvalue(inv)     # inv = inventory level of product i at the end of time period t
    s = getindex(m,:s);         s_sol = getvalue(s)         # s = sales of product i in period t

    # list is used by the operator agent
    for l in 1:N_products
        for i in 1:N_products
            if w_sol[i,l,1] > 0.9
                tot_t = te_sol[l,1]-ts_sol[l,1] # tot_t: total time of product i in period t_index
                prod_t = Θl_sol[i,l,1]          # prod_t: production time of product i in period t_index
                trans_t = tot_t - prod_t        # trans_t: transition time of product i in period t_index

                sc.list[l,1] = i
                sc.list[l,2] = prod_t
                sc.list[l,3] = round(trans_t,2)
                sc.list[l,4] = xl_sol[i,l,1]
            end
        end
    end

    # sells is used by the dispatch agent
    sc.sells[:] = s_sol[:,1]
end

# ------------------------------------------------------------------------------
#                                Section 4.2
#                           Communication function
# This function is used to communicate the planner decisions to the scheduler
# (i.e. this must be changed whenever you want to change the communication)
# ------------------------------------------------------------------------------
function planner_scheduler(m::JuMP.Model,sc::SCSimulationData)
    x = getindex(m,:x);    x_sol = getvalue(x)     # x = amount produced of product i in period t
    sc.info[:] = x_sol[:,2]
    sc.x_planner[:] = x_sol[:,2]
end

# ------------------------------------------------------------------------------
#                                Section 4.3
#                             Failure function
# This function is used to create a failure time for the process
# ------------------------------------------------------------------------------
function fail_machine(t_ini::Number)
    lambda = 168                    # Constant probability per hour to get a failure
    d_fail = Exponential(lambda)    # Exponential distribution
    t_fail = t_ini+rand(d_fail)           # Random failure time: time in which a failure will occur

    d_fail2 = Normal(2,0.5)    # Exponential distribution
    t_fail2 = rand(d_fail2)

    (t_fail,t_fail2)
end

# ------------------------------------------------------------------------------
#                                 Section 5
#                              Operator agent
# The operator agent read the list to know which works should be carry out
# during week t_index, and then carries out the process
# ------------------------------------------------------------------------------
@resumable function operator(env::Simulation,sc::SCSimulationData)
    # Reset of timeout to count between 0 and 168 each week
    @yield timeout(env,-now(sim))
    @yield timeout(env,(sc.t_index-1)*168.0)

    # cond is a boolean variable that is false only when the simulation time is
    # more than 168
    cond = true
    t_failu = 0

    for l in 1:N_products
        # fail_new is an array that describes the process failures
        fail_new = -1*ones(4,1)

        # Here the operator reads the list of works, and so can know what
        # product must be produced in the slot l of the week t_index and how
        # long it takes to carry it out
        i_ind = sc.list[l,1]
        prod_t = sc.list[l,2]
        trans_t = sc.list[l,3]
        xl = sc.list[l,4]

        if cond == true
            println("\n")
            println("The process worked with Product $(i_ind) in slot $l of week $(sc.t_index)")

            # Uncertainty of production rate: Normal distribution
            # The uncertainty should only be applied if there is any production time
            if prod_t > 0
                d_R = Normal(sc.R[convert(Int64,i_ind)]-45,50)
                R_alea = rand(d_R)
                prod_t_alea = xl/R_alea
                println("       The theoretical production time was of $(round(prod_t,2)) hr, but it was of $(round(prod_t_alea,2)) hr")
                prod_t = prod_t_alea
            else
                println("       Product $(i_ind) did not have any production time in slot $l")
            end

            # Uncertainty of transition time: Normal distribution
            # The uncertainty should only be applied if there is any transition time
            # trans_t >= 0.5 is because that is the minimal transition time in the model
            if trans_t >= 0.5
                d_trans_t = Normal(trans_t+0.1,0.2)
                trans_t_alea = rand(d_trans_t)
                println("       The theoretical transition time was of $(trans_t) hr, but it was of $(round(trans_t_alea,2)) hr")
                trans_t = trans_t_alea
            else
                println("       Product $(i_ind) did not have any transition time in slot $l")
            end

            @yield timeout(env,prod_t+trans_t)
            #println("       Time of slot $l in week $(sc.t_index) = ",now(sim))

            # Uncertainty of transition failure: If there was a failure, then
            # the a failure time is going to be added to the total time
            if now(sim) >= sc.fail_time[1]
                # The process had a failure
                println("---------->There was a failure of $(round(sc.fail_time[2],2)) hours in slot $l of week $(sc.t_index)")
                @yield timeout(env,sc.fail_time[2])

                # Set up the new failure time
                sc.fail_time = fail_machine(now(sim))
            else
                # The process did not have a failure
                println("           There was no failure during slot $l of week $(sc.t_index)")
            end

            println("       Time of slot $l in week $(sc.t_index) = ",now(sim))

            if round(now(sim),1) <= 168.0*(sc.t_index)
                # Update of the inventory because there was production time
                if prod_t > 0
                    sc.INVI[convert(Int64,i_ind)] += xl
                else
                    println("       Product $i_ind was not produced in slot $l of week $(sc.t_index) (The inventory was not updated)")
                end

                # Update the last product to be produced in week t_index
                sc.Winit = zeros(N_products)
                sc.Winit[convert(Int64,i_ind)] = 1
            else
                # If the remaining time of week t_index is not enough to complete
                # the task in slot l, then that task will not be carry out
                t_delay = round(now(sim),1)-168.0*(sc.t_index)

                println("\n")
                println("   The remaining time of week $(sc.t_index) is not enough to complete the task in slot $l")
                println("   $(N_products+1-l) job(s) could not be done completely in week $(sc.t_index) (including the slot $l)")

                # Update of the "fail list"
                if (N_products+1-l) >= 2
                    for l_ind in l:N_products
                        fail_new[1,1] = sc.t_index
                        fail_new[2,1] = l_ind
                        fail_new[3,1] = i_ind
                        fail_new[4,1] = xl
                        sc.fail_prod = hcat(sc.fail_prod,fail_new)
                    end
                else
                    fail_new[1,1] = sc.t_index
                    fail_new[2,1] = l
                    fail_new[3,1] = i_ind
                    fail_new[4,1] = xl
                    sc.fail_prod = hcat(sc.fail_prod,fail_new)
                end

                cond = false
            end
        end
    end
end

# ------------------------------------------------------------------------------
#                                 Section 6
#                               Dispatch agent
# ------------------------------------------------------------------------------
@resumable function dispatch(env::Simulation,sc::SCSimulationData)
    backlog = zeros(3,1)

    println("\n")
    println("    /\\_/\\        ")
    println("   (=^.^=)         ")
    println("   (\")_(\")_/     Dispatch agent")

    println("sc.INVI = $(sc.INVI)")
    println("sc.selss = $(sc.sells)")
    sc.INVI -= sc.sells

    for i in 1:N_products
        if round(sc.INVI[i],2) < 0
            backlog[1,1] = sc.t_index
            backlog[2,1] = i
            backlog[3,1] = -round(sc.INVI[i],2)

            println("   There was a backlog of product $i in week $(sc.t_index) of $(round(-sc.INVI[i],2)) units")
            sc.backlogs = hcat(sc.backlogs,backlog)
        else
            println("   There was no backlog of product $i in week $(sc.t_index)")
        end
    end
end

# ------------------------------------------------------------------------------
#                                 Section 7
#                             Main simulation
# ------------------------------------------------------------------------------
@resumable function start_sim(env::Simulation,sc::SCSimulationData)
    # Set up the first failure time
    sc.fail_time = fail_machine(0)

    for t_ind in 1:N_periods
        sc.t_index = t_ind
        println("-------------------------------------- Week #$(sc.t_index) ----------------------------------------")

        client_process = @process client(env,sc)
        @yield client_process

        if isodd(t_ind) == true
            planner_process = @process planner(env,sc)
            @yield planner_process
        else
            scheduler_process = @process scheduler(env,sc)
            @yield scheduler_process
        end

        operator_process = @process operator(env,sc)
        @yield operator_process

        dispatch_process = @process dispatch(env,sc)
        @yield dispatch_process
    end
    println("\n")
    println("                _                       _       _             _   _   _")
    println("  ___    ___   | |   ___    _ __  __   | |_    (_)   __ _    | | | | | |")
    println(" / __\\  / _ \\  | |  / _ \\  | '_ ''_ '  |  _ \\  | |  / _' |   | | | | | |")
    println("| (__  | (_) | | | | (_) | | | | | | | | |_) | | | | (_| |   |_| |_| |_|")
    println(" \\___/  \\___/  |_|  \\___/  |_| |_| |_| |_'__/  |_|  \\__'_|   (_) (_) (_)")

    final = size(sc.backlogs)
    println("\n")
    println("The process had $(final[2]-1) backlog(s) in total during the simulation")
    for ind in 2:final[2]
        println("   One in week $(round(sc.backlogs[1,ind],2)) of $(round(sc.backlogs[3,ind],2)) units of product $(round(sc.backlogs[2,ind],2))")
    end
end

s = SCSimulationData()
sim = Simulation()
@process start_sim(sim,s)

run(sim)

println("\n")
toc()

# ------------------------------------------------------------------------------
#                                    End
# ------------------------------------------------------------------------------

# Cuantificar bien los blacklogs (cuantos son y que tan grandes fueron) y asi tener una metrica mejor

# Creo que: si existe algun problema en el proceso (que no alcanzo el tiempo o
# que hubo una falla en una maquina), el proceso deberia producir hasta donde
# pueda.
# Por ejemplo, si no se tiene el tiempo suficiente,entonces la actividad no se
# lleva a cabo para nada, pero creo que se deberia llevar a cabo hasta donde sea
# posible
