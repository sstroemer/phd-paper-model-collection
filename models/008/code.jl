using JuMP
using HiGHS: HiGHS


function run_experiment()
    # Load from file.
    model = read_from_file("model.mps.gz")

    # Simulate extracting duals of some constraints.
    con = all_constraints(model, VariableRef, MOI.LessThan{Float64})

    # Config and solve.
    set_optimizer(model, HiGHS.Optimizer)
    set_attribute(model, "solver", "ipm")
    set_silent(model)
    optimize!(model)

    # Get stats.
    time_solve = solve_time(model)
    info_get_dobj = @timed dual_objective_value(model)
    info_get_duals = @timed shadow_price.(con)

    return time_solve, info_get_dobj.time, info_get_duals.time, info_get_dobj.bytes, info_get_duals.bytes
end

# Make sure it's compiled (since we are using `@timed` and no "proper" benchmarking package).
run_experiment()

# Benchmarking.
N = 15
results = [run_experiment() for _ in 1:N]

# Write out results.
print("| ", splitpath(Base.active_project())[end-1])
print(" | ", pkgversion(HiGHS))
print(" | ", "$(HiGHS.HIGHS_VERSION_MAJOR).$(HiGHS.HIGHS_VERSION_MINOR).$(HiGHS.HIGHS_VERSION_PATCH)")
print(" | ", round(sum(r[1] for r in results) / N; digits=4))
print(" | ", round(sum(r[2] for r in results) / N; digits=4))
print(" | ", round(sum(r[4] for r in results) / N / 1e6; digits=4))
print(" | ", round(sum(r[3] for r in results) / N; digits=4))
print(" | ", round(sum(r[5] for r in results) / N / 1e6; digits=4), " |")
println()
