using Scheduling
using Gurobi

# Define network
n = Network(:kd,"Kondili Example 1", solver=GurobiSolver(MIPGap=0.01, Threads=1, TimeLimit=200))
horizon = 336
capacity = 20*horizon
sethorizon(n, horizon)

# Define Materials
material(n, :A, "Raw Material A")
material(n, :B, "Raw Material B")
material(n, :C, "Raw Material C")
material(n, :D, "Raw Material C")
material(n, :AB, "Intermediate AB")
material(n, :BC, "Intermediate BC")
material(n, :CD, "Intermediate CD")
material(n, :E,"Impure E")
material(n, :W,"Waste")
material(n, :HotA,"Heated A")
material(n, :P1, "Product 1")
material(n, :P2, "Product 2")
setprice(n, :P1,10)
setprice(n, :P2,10)
material(n, :P3, "Product 3")
material(n, :P4, "Product 4")
setprice(n, :P3,14)
setprice(n, :P4,14)
for s in [:AB, :BC, :E, :HotA]
  setprice(n, s,-1)
end

# Define Units
unit(n, :Heater)
unit(n, :Reactor1)
unit(n, :Reactor2)
unit(n, :Reactor3)
unit(n, :Column,"Distillation column")

tank(n, :Tk_A,2e8)
tank(n, :Tk_B,2e8)
tank(n, :Tk_C,2e8)
tank(n, :Tk_D,2e8)
tank(n, :Tk_HotA,2e8)
tank(n, :Tk_AB,2e8)
tank(n, :Tk_BC,2e8)
tank(n, :Tk_CD,2e8)
tank(n, :Tk_E,2e8)
tank(n, :Tk_W,2e8)
tank(n, :Tk_P1,2e8)
tank(n, :Tk_P2,2e8)
tank(n, :Tk_P3,2e8)
tank(n, :Tk_P4,2e8)
setlevel(n, :Tk_A, :A, 2e8)
setlevel(n, :Tk_B, :B, 2e8)
setlevel(n, :Tk_C, :C, 2e8)
setlevel(n, :Tk_D, :D, 2e8)

# Define Processes
process(n, :Heating)
process(n, :Rx1)
process(n, :Rx2)
process(n, :Rx3)
process(n, :Rx4)
process(n, :Rx5)
process(n, :Separation1)
process(n, :Separation2)


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
# Reaction 4
addinlet(n, :Rx4,:C,0.4)
addinlet(n, :Rx4,:D,0.6)
addoutlet(n, :Rx4,:CD,1.0,1)
# Reaction 5
addinlet(n, :Rx5,:B,0.5)
addinlet(n, :Rx5,:D,0.5)
addoutlet(n, :Rx5,:W,0.05,1)
addoutlet(n, :Rx5,:P3,0.95,1)
# Separation 1
addinlet(n, :Separation1,:E,1.0)
addoutlet(n, :Separation1,:P2,0.9,2)
addoutlet(n, :Separation1,:AB,0.1,2)
# Separation 2
addinlet(n, :Separation2,:CD,1.0)
addoutlet(n, :Separation2,:P4,0.9,2)
addoutlet(n, :Separation2,:E,0.1,2)

## Add Data
# Processes executed by units
addprocess(n, :Heater,:Heating,0,100)
addprocess(n, :Reactor1,:Rx1,0,80)
addprocess(n, :Reactor1,:Rx2,0,80)
addprocess(n, :Reactor1,:Rx3,0,80)
addprocess(n, :Reactor1,:Rx4,0,80)
addprocess(n, :Reactor1,:Rx5,0,80)
addprocess(n, :Reactor2,:Rx1,0,50)
addprocess(n, :Reactor2,:Rx2,0,50)
addprocess(n, :Reactor2,:Rx3,0,50)
addprocess(n, :Reactor2,:Rx4,0,50)
addprocess(n, :Reactor2,:Rx5,0,50)
addprocess(n, :Reactor3,:Rx1,0,100)
addprocess(n, :Reactor3,:Rx2,0,100)
addprocess(n, :Reactor3,:Rx3,0,100)
addprocess(n, :Reactor3,:Rx4,0,100)
addprocess(n, :Reactor3,:Rx5,0,100)
addprocess(n, :Column,:Separation1,0,200)
addprocess(n, :Column,:Separation2,0,200)


## Connections
autoconnect(n)
