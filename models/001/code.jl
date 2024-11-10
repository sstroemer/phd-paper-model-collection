using JuMP
using Gurobi: Gurobi
using HiGHS: HiGHS

const GRB_ENV = Gurobi.Env()

function make_base_model(solver::Symbol)
    if solver == :highs
        model = Model(HiGHS.Optimizer)
        set_silent(model)
        set_attribute(model, "presolve", "off")
        set_attribute(model, "solver", "ipm")
        set_attribute(model, "run_crossover", "off")
    elseif solver == :gurobi
        model = Model(() -> Gurobi.Optimizer(GRB_ENV))
        set_silent(model)
        set_attribute(model, "Presolve", 0)
        set_attribute(model, "Method", 2)
        set_attribute(model, "Crossover", 0)
    else
        error("Unknown solver")
    end

    @variable(model, x >= 0)
    @objective(model, Min, x)

    return model
end

function make_table(solver::Symbol)
    @info "Making table" solver
    println("| rhs | 0.0 | 0.0 | 1.0 | 1.0 | 1e10 | 1e10 |")
    println("|:---:|:---:|:---:|:---:|:---:|:---:|:---:|")
    println("| result | rc | sp | rc | sp | rc | sp |")
    for fixedvar in [true, false]
        for dir in [true, false]
            print(
                "| dir = $(dir ? "normal" : "reverse") <br> rhs = $(fixedvar ? "fixed" : "constant") | ",
            )
            for val in [0.0, 1.0, 1e10]
                model = make_base_model(solver)

                fixedvar && @variable(model, rhs == val)
                fixedvar || (rhs = val)

                dir && @constraint(model, c, 3.0 * model[:x] >= rhs)
                dir || @constraint(model, c, -3.0 * model[:x] <= -rhs)

                optimize!(model)
                rc = fixedvar ? round(dual(FixRef(rhs)); digits=4) : "-"
                sp = round(dual(c); digits=4)

                print(rc, " | ", sp, " | ")
            end
            println()
        end
    end
end

make_table(:highs)
make_table(:gurobi)
