# Model 001

This showcases differences in the extraction of "dual results" from a simple model, formulated in different ways, that is solved using an interior point method without crossover. This might be the choice for solving large sub-models.

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
    \text{min} & \quad 1 \cdot x & \\
    \text{s.t.} & & \\
    & \quad 3 \cdot x \geq d & \\
    & \quad x \geq 0 &
\end{align}
$$

where $(3)$ is formulated either as given (`dir = normal`) or mutliplied by $-1$ (`dir = reverse`), resulting in $-3 \cdot x \leq d$. Further, the right hand side $d$ is either passed to the solver as floating point value (`rhs = constant`), or as fixed variable $y$ (`rhs = fixed`). The latter is a common approach in implementing a "parametric" right hand side, that can be set from the outside while still allowing an easy way to query the associated duals.

### Approach

To simulate an interior point solution with such a small model, persolve is turned off - otherwise the model would already be solved there.

## Results

The results given below test the model using:

1. Different values for the right hand side: `rhs` out of `[0.0, 1.0, 1e10]`.
2. Different ways to extract the dual associated with the "parametric bound" of $x$, by either querying the dual associated with the constraint $(3)$, or the one related to the fixing constraint of $y$ (which essentially does $y = d$).
3. Passing a "cached" model, vs. constructing it in `direct` mode - c.f. [direct mode](https://jump.dev/JuMP.jl/stable/manual/models/#Direct-mode).

Here `rc` ("reduced cost") is the result obtained from $y$ (therefore missing for all trials where `rhs` is set directly, indicated by `constant`), while `sp` ("shadow price") is obtained from the dual of $(3)$. Note that while the naming follows the functionality in `JuMP` we use the `dual(...)` function directly, to showcase that this is not an artifact related to the use of wrapper functions.

### HiGHS

#### `normal`

| rhs | 0.0 | 0.0 | 1.0 | 1.0 | 1e10 | 1e10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| result | rc | sp | rc | sp | rc | sp |
| dir = normal <br> rhs = fixed | 0.0407 | 0.0407 | 0.3333 | 0.3333 | 0.3333 | 0.0 |
| dir = reverse <br> rhs = fixed | 0.0407 | 0.0 | 0.3333 | 0.0 | 0.3333 | 0.0 |
| dir = normal <br> rhs = constant | - | 0.0823 | - | 0.3333 | - | 0.0 |
| dir = reverse <br> rhs = constant | - | 0.0 | - | 0.0 | - | 0.0 |

#### `direct`

| rhs | 0.0 | 0.0 | 1.0 | 1.0 | 1e10 | 1e10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| result | rc | sp | rc | sp | rc | sp |
| dir = normal <br> rhs = fixed | 0.0407 | 0.0407 | 0.3333 | 0.3333 | 0.0 | 0.0 | 
| dir = reverse <br> rhs = fixed | 0.0407 | 0.0 | 0.3333 | 0.0 | 0.0 | 0.0 | 
| dir = normal <br> rhs = constant | - | 0.0823 | - | 0.3333 | - | 0.0 | 
| dir = reverse <br> rhs = constant | - | 0.0 | - | 0.0 | - | 0.0 |

### Gurobi

#### `normal`

| rhs | 0.0 | 0.0 | 1.0 | 1.0 | 1e10 | 1e10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| result | rc | sp | rc | sp | rc | sp |
| dir = normal <br> rhs = fixed | 0.0603 | 0.0603 | 0.3333 | 0.3333 | 0.3333 | 0.3333 |
| dir = reverse <br> rhs = fixed | 0.0603 | -0.0603 | 0.3333 | -0.3333 | 0.3333 | -0.3333 |
| dir = normal <br> rhs = constant | - | 0.0964 | - | 0.3333 | - | 0.3333 |
| dir = reverse <br> rhs = constant | - | -0.0964 | - | -0.3333 | - | -0.3333 |

#### `direct`

| rhs | 0.0 | 0.0 | 1.0 | 1.0 | 1e10 | 1e10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| result | rc | sp | rc | sp | rc | sp |
| dir = normal <br> rhs = fixed | 0.0603 | 0.0603 | 0.3333 | 0.3333 | 0.3333 | 0.3333 | 
| dir = reverse <br> rhs = fixed | 0.0603 | -0.0603 | 0.3333 | -0.3333 | 0.3333 | -0.3333 | 
| dir = normal <br> rhs = constant | - | 0.0964 | - | 0.3333 | - | 0.3333 | 
| dir = reverse <br> rhs = constant | - | -0.0964 | - | -0.3333 | - | -0.3333 |
