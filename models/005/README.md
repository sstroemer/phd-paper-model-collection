# Model 005

This showcases that potential pitfalls with objective value extraction are not restricted to numerically challenging models. The following is taken from Gurobi's log:

```console
Coefficient statistics:
  Matrix range     [1e-01, 1e+00]
  Objective range  [1e+03, 5e+05]
  Bounds range     [0e+00, 0e+00]
  RHS range        [3e-03, 1e+00]
```

## Code

See [`code.jl`](./code.jl). This is using:

- `Gurobi v1.4.0`, using `Gurobi Optimizer version 11.0.3 build v11.0.3rc0`
- `JuMP v1.23.4`

## Details

N/A

## Approach

The code creates, using a fixed seed, a random lower triangular matrix $A$ and accompanying vectors $b$ and $c$, and uses these to construct a feasible problem to solve.

## Results

To compare the results, the model has been solved to optimality (as far as this can be guaranteed), by using Gurobi's simplex (with default settings), resulting in an objective value of `-219572.60804802092`.

The results showcase that `objective_value(model)` (which queries the `ObjVal` attribute) results in

- the **primal** objective value when solving the primal (`PreDual` = 0), but in
- the **dual** objective value when solving the dual (`PreDual` = 1).

While this might not seem problematic on first sight, the fact that `PreDual` may be automatically changed (when using default settings) by the solver shows that trusting `objective_value(model)` to return the (primal) objective might be a reasonable expectation from a user.

### `PreDual` = 0

```julia
objective_value(model)            # -219572.59920463097
get_fb_obj(model; obj = :primal)  # -219572.59920463097
get_fb_obj(model; obj = :dual)    # -219572.62494348988
```

### `PreDual` = 1

```julia
objective_value(model)            # -219572.85602469728
get_fb_obj(model; obj = :primal)  # -219572.15844466456
get_fb_obj(model; obj = :dual)    # -219572.85602469728
```
