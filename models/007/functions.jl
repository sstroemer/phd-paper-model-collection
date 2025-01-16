function print_iteration(k, args...)
    f(x) = (x isa Integer) || (x isa AbstractString) ? lpad(x, 15) : @sprintf("%11.2f", x)
    output = string("│ ", f(k), " │ ", join(f.(args), " │ "), " │")
    # println(output)
    return output
end

function run_model(model::JuMP.Model, attributes::Vector{<:Pair}, f_opt)
    set_optimizer(model, f_opt)
    set_silent(model)
    set_attributes(model, attributes...)
    optimize!(model)

    if solver_name(model) == "HiGHS"
        _solver = get(Dict(attributes), "solver", "choose")
        alg = _solver == "simplex" ? :simplex : (_solver == "ipm" ? :ipm : :unknown)
    elseif solver_name(model) == "Gurobi"
        _method = get(Dict(attributes), "Method", -1)
        alg = _method ∈ [0, 1] ? :simplex : (_method == 2 ? :ipm : :unknown)
    else
        alg = :unknown
    end

    if !is_solved_and_feasible(model)
        if (solver_name(model) == "HiGHS") &&
            (alg == :ipm) &&
            (termination_status(model) == MOI.OTHER_ERROR)
            # We "fake" check for IPM solves that may be used (but with caution).
            if (result_count(model) == 1) &&
                (raw_status(model) == "kHighsModelStatusUnknown")
                try
                    # The "fake" indication is: `MOI.OTHER_RESULT_STATUS`.
                    return (
                        solve_time(model),
                        barrier_iterations(model),
                        objective_value(model),
                        MOI.OTHER_RESULT_STATUS,
                    )
                catch
                    return -1, -1, -1, termination_status(model)
                end
            end
        elseif solver_name(model) == "Gurobi"
            return -1, -1, -1, termination_status(model)
        else
            return -1, -1, -1, termination_status(model)
        end
    end

    if alg == :simplex
        return solve_time(model),
        simplex_iterations(model), objective_value(model),
        termination_status(model)
    elseif alg == :ipm
        return solve_time(model),
        barrier_iterations(model), objective_value(model),
        termination_status(model)
    else
        return solve_time(model), -1, objective_value(model), termination_status(model)
    end
end

function ind2mat(ind, cols)
    return sparse(1:length(ind), ind, ones(length(ind)), length(ind), cols)
end

const _prepare_jump_conic_dual_cache = Dict{String,NamedTuple}()
# empty!(_prepare_jump_conic_dual_cache)
function _prepare_jump_conic_dual(filename::String)
    global _prepare_jump_conic_dual_cache

    if haskey(_prepare_jump_conic_dual_cache, filename)
        return _prepare_jump_conic_dual_cache[filename]
    end

    lpmd = lp_matrix_data(read_from_file(filename))

    indices = [
        findall(@. (lpmd.b_lower != lpmd.b_upper) & isfinite(lpmd.b_lower)),
        findall(@. (lpmd.b_lower != lpmd.b_upper) & isfinite(lpmd.b_upper)),
        findall(lpmd.b_lower .== lpmd.b_upper),
        findall(isfinite.(lpmd.x_lower)),
        findall(isfinite.(lpmd.x_upper)),
    ]

    a_0 = lpmd.c
    b_0 = lpmd.c_offset

    A = lpmd.A
    A_1 = vcat(lpmd.A[indices[1], :], ind2mat(indices[4], size(A, 2)))
    A_2 = vcat(lpmd.A[indices[2], :], ind2mat(indices[5], size(A, 2)))
    A_3 = lpmd.A[indices[3], :]

    b_1 = vcat(lpmd.b_lower[indices[1]], lpmd.x_lower[indices[4]])
    b_2 = vcat(lpmd.b_upper[indices[2]], lpmd.x_upper[indices[5]])
    b_3 = lpmd.b_lower[indices[3]]  # `b_lower == b_upper` here

    _prepare_jump_conic_dual_cache[filename] = (
        a_0=a_0, b_0=b_0, A_1=A_1, A_2=A_2, A_3=A_3, b_1=b_1, b_2=b_2, b_3=b_3
    )

    return _prepare_jump_conic_dual_cache[filename]
end

function create_jump_conic_dual(filename::String)
    # See: https://jump.dev/JuMP.jl/stable/moi/background/duality/

    data = _prepare_jump_conic_dual(filename)
    dual_model = Model()

    y_1 = @variable(dual_model, [1:size(data.A_1, 1)], lower_bound = 0)
    y_2 = @variable(dual_model, [1:size(data.A_2, 1)], upper_bound = 0)
    y_3 = @variable(dual_model, [1:size(data.A_3, 1)])

    @constraint(
        dual_model, data.A_1' * y_1 .+ data.A_2' * y_2 .+ data.A_3' * y_3 .== data.a_0
    )
    @objective(
        dual_model, Max, data.b_1' * y_1 + data.b_2' * y_2 + data.b_3' * y_3 + data.b_0
    )

    return dual_model
end

const _prepare_general_dual_cache = Dict{String,NamedTuple}()
# empty!(_prepare_general_dual_cache)
function _prepare_general_dual(filename::String)
    global _prepare_general_dual_cache

    if haskey(_prepare_general_dual_cache, filename)
        return _prepare_general_dual_cache[filename]
    end

    lpmd = lp_matrix_data(read_from_file(filename))

    indices = [
        findall(@. (lpmd.b_lower != lpmd.b_upper) & isfinite(lpmd.b_lower)),
        findall(@. (lpmd.b_lower != lpmd.b_upper) & isfinite(lpmd.b_upper)),
        findall(lpmd.b_lower .== lpmd.b_upper),
        findall(@. (lpmd.x_lower != 0.0) & isfinite(lpmd.x_lower)),
        findall(@. (lpmd.x_upper != 0.0) & isfinite(lpmd.x_upper)),
        findall(lpmd.x_lower .== 0.0),
        findall(lpmd.x_upper .== 0.0),
        findall(@. !(isfinite(lpmd.x_lower) | isfinite(lpmd.x_upper))),
    ]

    c = lpmd.c

    A_M_L = vcat(lpmd.A[indices[2], :], ind2mat(indices[5], size(lpmd.A, 2)))
    b_M_L = vcat(lpmd.b_upper[indices[2]], lpmd.x_upper[indices[5]])

    A_M_E = lpmd.A[indices[3], :]
    b_M_E = lpmd.b_lower[indices[3]]  # `b_lower == b_upper` here

    A_M_G = vcat(lpmd.A[indices[1], :], ind2mat(indices[4], size(lpmd.A, 2)))
    b_M_G = vcat(lpmd.b_lower[indices[1]], lpmd.x_lower[indices[4]])

    D_L = indices[7]
    D_F = indices[8]
    D_G = indices[6]

    A = vcat(A_M_L, A_M_E, A_M_G)

    _prepare_general_dual_cache[filename] = (
        c=c,
        A=A,
        A_M_L=A_M_L,
        A_M_E=A_M_E,
        A_M_G=A_M_G,
        b_M_L=b_M_L,
        b_M_E=b_M_E,
        b_M_G=b_M_G,
        D_L=D_L,
        D_F=D_F,
        D_G=D_G,
    )

    return _prepare_general_dual_cache[filename]
end

function create_general_dual(filename::String)
    # See: https://dabeenl.github.io/IE331_lecture9_note.pdf
    # (as one example formulation of a dual problem for a "general" LP)

    data = _prepare_general_dual(filename)
    dual_model = Model()

    λ_L = @variable(dual_model, [1:size(data.A_M_L, 1)], upper_bound = 0)
    λ_E = @variable(dual_model, [1:size(data.A_M_E, 1)])
    λ_G = @variable(dual_model, [1:size(data.A_M_G, 1)], lower_bound = 0)
    λ = vcat(λ_L, λ_E, λ_G)

    @constraint(dual_model, data.A[:, data.D_L]' * λ .>= data.c[data.D_L])
    @constraint(dual_model, data.A[:, data.D_F]' * λ .== data.c[data.D_F])
    @constraint(dual_model, data.A[:, data.D_G]' * λ .<= data.c[data.D_G])

    @objective(dual_model, Max, data.b_M_L' * λ_L + data.b_M_E' * λ_E + data.b_M_G' * λ_G)

    return dual_model
end

function _get_stats(jm)
    lpmd = lp_matrix_data(jm)
    A = lpmd.A
    return (size(A')..., nnz(A))
end

function analyse_models(filenames)
    open("out/model_stats.csv", "w") do io
        write(io, "model,version,variables,constraints,nonzeros\n")
    end

    for fn in filenames
        sn = split(fn, "/")[2]

        @info "$fn (original)"
        open("model_stats.csv", "a") do io
            write(io, join((sn, "original", _get_stats(read_from_file(fn))...), ",") * "\n")
        end

        @info "$fn (jump_conic_dual)"
        open("model_stats.csv", "a") do io
            write(
                io,
                join(
                    (sn, "jump_conic_dual", _get_stats(create_jump_conic_dual(fn))...), ","
                ) * "\n",
            )
        end

        @info "$fn (general_dual)"
        open("model_stats.csv", "a") do io
            write(
                io,
                join((sn, "general_dual", _get_stats(create_general_dual(fn))...), ",") *
                "\n",
            )
        end
    end
end
