using JuMP
using Gurobi: Gurobi
using HiGHS: HiGHS
using Printf: @sprintf
using OrderedCollections: OrderedDict
using Dates: now
using SparseArrays: sparse, nnz

const GRB_ENV = Gurobi.Env()

include("functions.jl")

# Use this for timestamped result files:
# output_file = "out/results_$(replace(string(now()), ":" => "")).csv"
output_file = "out/results.csv"

# Models to test.
models = [
    "models/$(i).mps" for
    i in [744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760]
]
# analyse_models(models)

# Run that many solves for each test case, then average.
N = 5

# Test cases for Gurobi and HiGHS.
test_cases = OrderedDict(
    :gurobi => OrderedDict(
        # Primal simplex, solving the primal.
        0x01 => ["Method" => 0, "PreDual" => 0],
        # Primal simplex, solving the dual.
        0x02 => ["Method" => 0, "PreDual" => 1],
        # Dual simplex, solving the primal.
        0x03 => ["Method" => 1, "PreDual" => 0],
        # Dual simplex, solving the dual.
        0x04 => ["Method" => 1, "PreDual" => 1],
        # Barrier, solving the primal.
        0x05 => [
            "Method" => 2,
            "PreDual" => 0,
            "Crossover" => 0,
            "BarConvTol" => 1e-5,
            "FeasibilityTol" => 1e-5,
            "OptimalityTol" => 1e-5,
            "BarHomogeneous" => 0,
        ],
        # Barrier, solving the dual.
        0x06 => [
            "Method" => 2,
            "PreDual" => 1,
            "Crossover" => 0,
            "BarConvTol" => 1e-5,
            "FeasibilityTol" => 1e-5,
            "OptimalityTol" => 1e-5,
            "BarHomogeneous" => 0,
        ],
        # Hom. Barrier, solving the primal.
        0x07 => [
            "Method" => 2,
            "PreDual" => 0,
            "Crossover" => 0,
            "BarConvTol" => 1e-5,
            "FeasibilityTol" => 1e-5,
            "OptimalityTol" => 1e-5,
            "BarHomogeneous" => 1,
        ],
        # Hom. Barrier, solving the dual.
        0x08 => [
            "Method" => 2,
            "PreDual" => 1,
            "Crossover" => 0,
            "BarConvTol" => 1e-5,
            "FeasibilityTol" => 1e-5,
            "OptimalityTol" => 1e-5,
            "BarHomogeneous" => 1,
        ],
    ),
    :highs => OrderedDict(
        # Dual (serial) simplex.
        0x01 => ["solver" => "simplex", "simplex_strategy" => 1],
        # Dual (PAMI) simplex.
        0x02 => ["solver" => "simplex", "simplex_strategy" => 2],
        # Dual (SIP) simplex.
        0x03 => ["solver" => "simplex", "simplex_strategy" => 3],
        # Primal simplex.
        0x04 => ["solver" => "simplex", "simplex_strategy" => 4],
        # IPM.
        0x05 => [
            "solver" => "ipm",
            "run_crossover" => "off",
            "primal_feasibility_tolerance" => 1e-5,
            "dual_feasibility_tolerance" => 1e-5,
            "ipm_optimality_tolerance" => 1e-5,
            "primal_residual_tolerance" => 1e-5,
            "dual_residual_tolerance" => 1e-5,
        ],
    ),
)

# Track experiment number, and allow skipping (to re-start from a specific experiment).
i_tc = 1
start_at = 1

# Write CSV file header (unless we are resuming something).
if start_at == 1
    open(output_file, "w") do io
        header = "experiment,model,solver,mode,test_case,avg_sec,avg_iter,objective,termination,numerical_issues,presolve"
        write(io, "$(header)\n")
    end
end

# Run experiments.
for file in models
    # Naive model name without folder.
    sn = split(file, "/")[2]

    for solver in keys(test_cases)
        f_opt = solver == :gurobi ? (() -> Gurobi.Optimizer(GRB_ENV)) : HiGHS.Optimizer

        for mode in [:primal, :jump_conic_dual, :general]
            for (k, tc) in test_cases[solver]
                # Skip running simplex for large models.
                size = parse(Int, split(sn, ".")[1])
                if size > 3624
                    (("solver" => "simplex") in tc) && continue
                    ((("Method" => 0) in tc) || (("Method" => 1) in tc)) && continue
                end

                # Check, if we should skip this experiment.
                if i_tc < start_at
                    @info "Skipping [$(sn)]: $(solver) | mode=$(mode) | test-case #$(k)"

                    global i_tc += 1
                    continue
                end

                @info "Running [$(sn)]: $(solver) | mode=$(mode) | test-case #$(k)"

                # Copy the test case to avoid modifying the original (when adding "NumericFocus", etc.).
                tc = copy(tc)

                # Track results.
                results = []
                numerical_issues = false
                presolve_disabled = false

                for itry in 1:N
                    while true
                        res = run_model((
                            if mode == :primal
                                read_from_file(file)
                            elseif mode == :jump_conic_dual
                                create_jump_conic_dual(file)
                            elseif mode == :general
                                create_general_dual(file)
                            else
                                nothing
                            end
                        ), tc, f_opt)

                        if (itry == 1) && (res[4] != MOI.OPTIMAL)
                            numerical_issues = true

                            # Try to "fix" numerical issues and ...
                            if (solver == :gurobi) && !presolve_disabled
                                # Which we can only do for Gurobi, and only until we disable presolve as last measure.

                                if tc[end] == ("NumericFocus" => 3)
                                    # We already tried "NumericFocus", last chance: disable presolve.
                                    # See: https://docs.gurobi.com/projects/optimizer/en/current/concepts/numericguide/numeric_parameters.html#presolve
                                    push!(tc, "Presolve" => 0)
                                    presolve_disabled = true

                                    # ... try again.
                                    continue
                                else
                                    push!(tc, "NumericFocus" => 3)

                                    # ... try again.
                                    continue
                                end
                            else
                                # Can't do much here.
                            end
                        end

                        # Always break, we are just using the while for an easy resolve.
                        push!(results, res)
                        break
                    end

                    if results[end][4] ∉ (MOI.OPTIMAL, MOI.OTHER_RESULT_STATUS)
                        # No need to repeatedly fail to solve.
                        # We are "faking" `OTHER_RESULT_STATUS` for HiGHS with numerical errors.
                        break
                    end
                end

                # Append line to CSV file.
                open(output_file, "a") do io
                    write(
                        io,
                        strip(
                            replace(
                                print_iteration(
                                    i_tc,
                                    sn,
                                    string(solver),
                                    string(mode),
                                    k,
                                    sum(it[1] for it in results) / N,
                                    sum(it[2] for it in results) / N,
                                    results[1][3],
                                    string(results[1][4]),
                                    numerical_issues ? "yes" : "no",
                                    presolve_disabled ? "no" : "yes",
                                ),
                                "│" => ",",
                                " " => "",
                            ),
                        )[2:(end - 1)] * "\n",
                    )
                end

                global i_tc += 1
            end
        end
    end
end
