using JuMP
import Gurobi
import Random, LinearAlgebra


function get_fb_obj(model::JuMP.Model; obj::Symbol)
    (obj == :primal) && return MOIU.get_fallback(unsafe_backend(model), MOI.ObjectiveValue(1))
    (obj == :dual) && return MOIU.get_fallback(unsafe_backend(model), MOI.DualObjectiveValue(1), Float64)
    error("Unknown objective type: $obj")
end

# ------------------------------------------------------------

model = Model(Gurobi.Optimizer)

set_attribute(model, "Method", 2)
set_attribute(model, "Crossover", 0)
set_attribute(model, "PreDual", 0)
set_attribute(model, "BarConvTol", 1e-2)

N = 1000
Random.seed!(42)
A = LinearAlgebra.tril!(Random.rand(N, N) .+ 0.1)
b = Random.rand(N)
c = 100 * Random.rand(N) .- 50.0

@variable(model, z[i=1:N] >= 0)
@constraint(model, A * z .<= b)

@objective(model, Min, c' * z * 1e4)

optimize!(model)

BEST = -219572.60804802092

objective_value(model)            # -219572.59920463097
get_fb_obj(model; obj = :primal)  # -219572.59920463097
get_fb_obj(model; obj = :dual)    # -219572.62494348988

# For `PreDual = 1`:
# objective_value(model)            # -219572.85602469728
# get_fb_obj(model; obj = :primal)  # -219572.15844466456
# get_fb_obj(model; obj = :dual)    # -219572.85602469728
