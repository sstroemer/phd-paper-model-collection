import Random, LinearAlgebra

model = Model(Gurobi.Optimizer)

set_attribute(model, "Method", 2)
set_attribute(model, "Crossover", 0)
set_attribute(model, "PreDual", 0)
set_attribute(model, "BarConvTol", 1e-2)

N = 100
Random.seed!(42)
A = LinearAlgebra.tril!(Random.rand(N, N) .+ 0.1)
b = Random.rand(N)
c = 100 * Random.rand(N) .- 50.0

@variable(model, z[i=1:N] >= 0)
@constraint(model, A * z .<= b)

@objective(model, Min, c' * z * 1e4)

optimize!(model)

BEST = -131179.62476663897 / 1e2

objective_value(model) / BEST
MOI.Utilities.get_fallback(unsafe_backend(model), MOI.ObjectiveValue(1)) / BEST
MOI.Utilities.get_fallback(unsafe_backend(model), MOI.DualObjectiveValue(1), Float64) / BEST

