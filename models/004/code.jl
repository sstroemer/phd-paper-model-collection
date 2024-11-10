using JuMP
import Gurobi

function get_fb_obj(model::JuMP.Model; obj::Symbol)
    (obj == :primal) && return MOIU.get_fallback(unsafe_backend(model), MOI.ObjectiveValue(1))
    (obj == :dual) && return MOIU.get_fallback(unsafe_backend(model), MOI.DualObjectiveValue(1), Float64)
    error("Unknown objective type: $obj")
end

function load_model()
    model = read_from_file("models/004/model.mps")
    set_optimizer(model, Gurobi.Optimizer)
    set_attribute(model, "Method", 2)
    set_attribute(model, "Crossover", 0)
    set_attribute(model, "NumericFocus", 3)
    
    return model
end

# ------------------------------------------------------------

model = load_model()
set_attribute(model, "BarConvTol", 1e-3)
set_attribute(model, "PreDual", 0)
optimize!(model)

objective_value(model)            # 276997.2389653433
get_fb_obj(model; obj = :primal)  # 276997.2389653433
get_fb_obj(model; obj = :dual)    # 276997.02234643674

# ------------------------------------------------------------

model = load_model()
set_attribute(model, "BarConvTol", 1e-3)
set_attribute(model, "PreDual", 1)
optimize!(model)

objective_value(model)            # 276041.57983460044
get_fb_obj(model; obj = :primal)  # 277773.33495775046
get_fb_obj(model; obj = :dual)    # -51195.53690508625
