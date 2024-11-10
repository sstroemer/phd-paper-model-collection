import Random, LinearAlgebra
using JuMP
using Gurobi: Gurobi
using HiGHS: HiGHS

const GRB_ENV = Gurobi.Env()

function make_base_model(solver::Symbol, mode::Symbol; free::Bool, presolve::Bool, scale::Float64 = 1.0)
    if solver == :highs
        opt = HiGHS.Optimizer()
        model = mode == :direct ? direct_model(opt) : Model(() -> opt)
        set_silent(model)
        set_attribute(model, "presolve", presolve ? "on" : "off")
        set_attribute(model, "solver", "ipm")
        set_attribute(model, "run_crossover", "off")
    elseif solver == :gurobi
        opt = Gurobi.Optimizer(GRB_ENV)
        model = mode == :direct ? direct_model(opt) : Model(() -> opt)
        set_silent(model)
        set_attribute(model, "Presolve", presolve ? 1 : 0)
        set_attribute(model, "Method", 2)
        set_attribute(model, "Crossover", 0)
    else
        error("Unknown solver")
    end

    free && @variable(model, x)
    free || @variable(model, x >= 0.0)

    # Add some random stuff to make the problem non-trivial (= not solved in presolve, if active).
    begin
        N = 1000
        Random.seed!(42)
        A = LinearAlgebra.tril!(Random.rand(N, N))
        b = Random.rand(N)
        c = 2 * Random.rand(N) .- 1.0

        @variable(model, z[i = 1:N] >= 0)
        @constraint(model, A * z .<= b)
    end

    @objective(model, Min, (100.0 * x + c' * z) * scale)

    return model
end

function make_table(solver::Symbol, mode::Symbol; free::Bool)
    println("| rhs<br>result | 0.0<br>rc | 0.0<br>sp | 1.0<br>rc | 1.0<br>sp | 1e10<br>rc | 1e10<br>sp |")
    println("|:---:|:---:|:---:|:---:|:---:|:---:|:---:|")
    for presolve in [false, true]
        for fixedvar in [true, false]
            for dir in [true, false]
                print("| ")
                print("dir = $(dir ? "normal" : "reverse") <br>")
                print("rhs = $(fixedvar ? "fixed" : "constant") <br>")
                print("presolve = $(presolve ? "on" : "off") | ")
                for val in [0.0, 1.0, 1e10]
                    model = make_base_model(solver, mode; free, presolve)

                    fixedvar && @variable(model, rhs == val)
                    fixedvar || (rhs = val)

                    dir && @constraint(model, c, 3.0 * model[:x] >= rhs)
                    dir || @constraint(model, c, -3.0 * model[:x] <= -rhs)

                    optimize!(model)
                    rc = fixedvar ? round(dual(FixRef(rhs)); digits=2) : "-"
                    sp = round(dual(c); digits=2)

                    print(rc, " | ", sp, " | ")
                end
                println()
            end
        end
        println("| | | | | | | |")
    end

    println("")
end

println("### HiGHS\n")

println("#### `normal`\n")
println("**Including \\$(4)\$\$**  ")
make_table(:highs, :normal; free=false)
println("**Excluding \$(4)\$**  ")
make_table(:highs, :normal; free=true)

println("#### `direct`\n")
println("**Including \$(4)\$**  ")
make_table(:highs, :direct; free=false)
println("**Excluding \$(4)\$**  ")
make_table(:highs, :direct; free=true)

println("### Gurobi\n")

println("#### `normal`\n")
println("**Including \$(4)\$**  ")
make_table(:gurobi, :normal; free=false)
println("**Excluding \$(4)\$**  ")
make_table(:gurobi, :normal; free=true)

println("#### `direct`\n")
println("**Including \$(4)\$**  ")
make_table(:gurobi, :direct; free=false)
println("**Excluding \$(4)\$**  ")
make_table(:gurobi, :direct; free=true)
