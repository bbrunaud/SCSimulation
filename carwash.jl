# Este es un ejemplo de simulacion de varias maquinas en paralelo utilizando
# request de SimJulia

using ResumableFunctions
using SimJulia

Num_Maquinas = 2
Orders = zeros(Num_Maquinas,2,4)
                  #product ts       tp       trt
Orders[1,:,:] = [ 1        0        120      22
                  2        142      276      10]
Orders[2,:,:] = [ 4        0        124      6
                  3        130      288      24]

@resumable function car(env::Environment, name::Int, bcs::Resource, driving_time::Number, charge_duration::Number, mach::Number)
  @yield timeout(sim, driving_time)
  println(name, " arriving at ", now(env), " to machine ", mach)
  @yield request(bcs)
  println(name, " starting to charge at ", now(env), " in machine ", mach)
  @yield timeout(sim, charge_duration)
  println(name, " leaving the bcs at ", now(env), " of machine ", mach)
  @yield release(bcs)
end

sim = Simulation()
bcs = Resource(sim, 1)
bcs2 = Resource(sim, 1)

for i in 1:4
  if isodd(i) == true
    @process car(sim, i, bcs, 2i, 5, 1)
  else
    @process car(sim, i, bcs2, 2i, 5, 2)
  end
end

run(sim)
