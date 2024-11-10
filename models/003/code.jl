using JuMP
import Gurobi

function get_fb_primal_obj(model::JuMP.Model)
    return MOIU.get_fallback(unsafe_backend(model), MOI.ObjectiveValue(1))
end

function get_fb_dual_obj(model::JuMP.Model)
    return MOIU.get_fallback(unsafe_backend(model), MOI.DualObjectiveValue(1), Float64)
end

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

get_fb_primal_obj(model)
get_fb_dual_obj(model)

MOI.get(model, Gurobi.ModelAttribute("DualVio"))
