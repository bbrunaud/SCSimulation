using Scheduling
using Gurobi

# Define network
n = Network(:kd,"Kondili Example 1", solver=GurobiSolver())
horizon = 336
capacity = 20*horizon
sethorizon(n, horizon)

# Define Materials
material(n, :A, "Raw Material A")
material(n, :B, "Raw Material B")
material(n, :C, "Raw Material C")
material(n, :AB, "Intermediate AB")
material(n, :BC, "Intermediate BC")
material(n, :E,"Impure E")
material(n, :HotA,"Heated A")
material(n, :P1, "Product 1")
material(n, :P2, "Product 2")
setprice(n, :P1,10)
setprice(n, :P2,10)
for s in [:AB, :BC, :E, :HotA]
  setprice(n, s,-1)
end

# Define Units
unit(n, :Heater)
unit(n, :Reactor1)
unit(n, :Reactor2)
unit(n, :Column,"Distillation column")

tank(n, :Tk_A,capacity)
tank(n, :Tk_B,capacity)
tank(n, :Tk_C,capacity)
tank(n, :Tk_HotA,100)
tank(n, :Tk_AB,200)
tank(n, :Tk_BC,150)
tank(n, :Tk_E,100)
tank(n, :Tk_P1,2*capacity)
tank(n, :Tk_P2,2*capacity)
setlevel(n, :Tk_A, :A,capacity)
setlevel(n, :Tk_B, :B,capacity)
setlevel(n, :Tk_C, :C,capacity)

# Define Processes
process(n, :Heating)
process(n, :Rx1)
process(n, :Rx2)
process(n, :Rx3)
process(n, :Separation)


## Recipes
# Heating
addinlet(n, :Heating,:A,1.0)
addoutlet(n, :Heating,:HotA,1.0,1)
# Reaction 2
addinlet(n, :Rx2,:B,0.5)
addinlet(n, :Rx2,:C,0.5)
addoutlet(n, :Rx2,:BC,1.0,2)
# Reaction 1
addinlet(n, :Rx1,:HotA,0.4)
addinlet(n, :Rx1,:BC,0.6)
addoutlet(n, :Rx1,:AB,0.6,2)
addoutlet(n, :Rx1,:P1,0.4,2)
# Reaction 3
addinlet(n, :Rx3,:C,0.2)
addinlet(n, :Rx3,:AB,0.8)
addoutlet(n, :Rx3,:E,1.0,1)
# Separation
addinlet(n, :Separation,:E,1.0)
addoutlet(n, :Separation,:P2,0.9,2)
addoutlet(n, :Separation,:AB,0.1,2)

## Add Data
# Processes executed by units
addprocess(n, :Heater,:Heating,0,100)
addprocess(n, :Reactor1,:Rx1,0,80)
addprocess(n, :Reactor1,:Rx2,0,80)
addprocess(n, :Reactor1,:Rx3,0,80)
addprocess(n, :Reactor2,:Rx1,0,50)
addprocess(n, :Reactor2,:Rx2,0,50)
addprocess(n, :Reactor2,:Rx3,0,50)
addprocess(n, :Column,:Separation,0,200)


## Connections
autoconnect(n)
