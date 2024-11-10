using JuMP
using Gurobi: Gurobi

function get_fb_obj(model::JuMP.Model; obj::Symbol)
    (obj == :primal) &&
        return MOIU.get_fallback(unsafe_backend(model), MOI.ObjectiveValue(1))
    (obj == :dual) &&
        return MOIU.get_fallback(unsafe_backend(model), MOI.DualObjectiveValue(1), Float64)
    return error("Unknown objective type: $obj")
end

# ------------------------------------------------------------

model = read_from_file("models/003/model.mps")
set_optimizer(model, Gurobi.Optimizer)
set_attribute(model, "Method", 2)
set_attribute(model, "Crossover", 0)
set_attribute(model, "NumericFocus", 3)

optimize!(model)

primal_status(model)
dual_status(model)
termination_status(model)
has_values(model)
has_duals(model)

objective_value(model)
objective_value(model) >= 276997.16415941337
dual_objective_value(model)

get_fb_obj(model; obj=:primal)
get_fb_obj(model; obj=:dual)

MOI.get(model, Gurobi.ModelAttribute("DualVio"))
