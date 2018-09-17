using Base.Test

@testset "Package Load" begin include("test_packageload.jl") end
@testset "Demand Planner" begin include("test_forecast.jl") end
@testset "Logistics Planner" begin include("test_logistics.jl") end
@testset "Tactical Planner" begin include("test_planner.jl") end
