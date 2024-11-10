# Model 002

This showcases how iterative solves, which may re-use previous solutions to warm-start the next, may produce different results than ones obtained from a "fresh" solve. These may be seen as potentially even wrong, and may further vary based on solver settings.

## Code

See [`code.jl`](./code.jl). This is using:

- `Gurobi v1.4.0`, using `Gurobi Optimizer version 11.0.3 build v11.0.3rc0`
- `HiGHS v1.12.0`, using `HiGHS 1.8.0 (git hash: fcfb534146)`
- `JuMP v1.23.4`

## Details

### Model

The model being solved is

$$
\begin{align}
    \text{min} & \quad \frac{x}{0.1} \\
    \text{s.t.} & \\
    & \quad 3 \cdot x \geq y \\
    & \quad x \geq 0
\end{align}
$$

where $y$ is a fixed variable, that is for example used to parameterize the model for iterative solves.

### Approach

This follows the steps:

1. Solve the model with $y > 0$, making sure that $(3)$ is binding, which results in non-zero duals.
2. Change $y$ to $0$. Now both $(3)$ and $(4)$ (the non-negativity variable bound) are binding in an optimal solution.
3. Compare the result of step 2 to one obtained by creating a fresh model and immediately setting $y = 0$.

## Results

### HiGHS

```julia
run_experiment(:highs)
```

```console
┌ Info: highs: 1st
│   rc = 3.33
└   sp = 3.33
┌ Info: highs: 2nd
│   rc = 3.33
└   sp = 3.33
┌ Info: highs: clean
│   rc = 0.0
└   sp = 0.0
```

### Gurobi

```julia
run_experiment(:gurobi)
```

```console
┌ Info: gurobi: 1st
│   rc = 3.33
└   sp = 3.33
┌ Info: gurobi: 2nd
│   rc = 3.33
└   sp = 3.33
┌ Info: gurobi: clean
│   rc = 3.33
└   sp = 3.33
```

#### Changing `PreDual`

This forces `PreDual` to `1`, leading to the solver dualizing the model before solving it.

```julia
run_experiment(:gurobi; predual = 1)
```

```console
┌ Info: gurobi: 1st
│   rc = 3.33
└   sp = 3.33
┌ Info: gurobi: 2nd
│   rc = 3.33
└   sp = 3.33
┌ Info: gurobi: clean
│   rc = 0.0
└   sp = 0.0
```
