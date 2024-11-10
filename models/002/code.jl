using JuMP
using Gurobi: Gurobi
using HiGHS: HiGHS

function make_model(solver::Symbol; predual::Int64)
    if solver == :gurobi
        opt = Gurobi.Optimizer()
        model = direct_model(opt)
        set_attribute(model, "Method", 1)
        set_attribute(model, "PreDual", predual)
    elseif solver == :highs
        opt = HiGHS.Optimizer()
        model = direct_model(opt)
        set_attribute(model, "simplex_strategy", 1)  # default, but to be sure
    else
        error("Unknown solver")
    end

    @variable(model, x >= 0)
    @variable(model, y == 1.0)
    @constraint(model, c, 3.0 * x >= y)
    @objective(model, Min, x / 0.1)

    return model, y, c
end

function run_experiment(solver::Symbol; predual::Int64=0)
    @info "=================================================="
    @info "Starting with: $solver"

    model, y, c = make_model(solver; predual)

    @info "--------------------------------------------------"
    optimize!(model)
    @info "$(solver): 1st" rc = round(dual(FixRef(y)); digits=2) sp = round(
        dual(c); digits=2
    )

    @info "--------------------------------------------------"
    fix(y, 0.0; force=true)
    optimize!(model)
    @info "$(solver): 2nd" rc = round(dual(FixRef(y)); digits=2) sp = round(
        dual(c); digits=2
    )

    @info "--------------------------------------------------"
    model, y, c = make_model(solver; predual)
    fix(y, 0.0; force=true)
    optimize!(model)
    @info "$(solver): clean" rc = round(dual(FixRef(y)); digits=2) sp = round(
        dual(c); digits=2
    )

    @info "=================================================="
end

run_experiment(:highs)

run_experiment(:gurobi)

run_experiment(:gurobi; predual=1)
