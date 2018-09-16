using JuMP
using Cbc

N = 4

function rafa(Dem)
    m = Model(solver=CbcSolver())
    @variable(m, x[i in 1:N] >= 0,Int)
    @variable(m, y[i in 1:N] >= 0)
    @constraint(m, eq1[i in 1:N], x[i] <= 10*Dem)
    @constraint(m, eq2[i in 1:N], y[i] <= 10*Dem)
    @objective(m, Max, sum(x[i]+y[i] for i in 1:N))

    m
end
