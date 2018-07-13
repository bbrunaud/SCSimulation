using SimJulia
using ResumableFunctions

mutable struct SCSimulationData
  trip_duration::Int64
  charge_duration::Int64
end

function SCSimulationData()
  a = 2
  s = SCSimulationData(a,5)
end

@resumable function charge(env::Simulation, sc::SCSimulationData)
         sc.trip_duration = rand(1:4)
         println("Charging for $(sc.charge_duration)")
         @yield timeout(env, sc.charge_duration)
       end

@resumable function car(env::Simulation, sc::SCSimulationData)
                    while true
                      println("Start parking and charging at ", now(env))
                      sc.charge_duration = rand(3:6)
                      charge_process = @process charge(env, sc)
                      @yield charge_process
                      println("Start driving at ", now(env))
                      println("Driving for = ",sc.trip_duration)
                      @yield timeout(env, sc.trip_duration)
                    end
                  end

s = SCSimulationData()
sim = Simulation()
@process car(sim, s)

run(sim, 30)
