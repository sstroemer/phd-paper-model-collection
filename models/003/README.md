# Model 003

This showcases potential errors, or wrongfully extracted results, on numerically challenging (but small) models solved using an interior point method.

## Code

See [`code.jl`](./code.jl). This is using:

- `Gurobi v1.4.0`, using `Gurobi Optimizer version 11.0.3 build v11.0.3rc0`
- `JuMP v1.23.4`

## Details

The supplied model file (see [model.mps](./model.mps)) is the result of a few iterations of cuts being added to a small main-problem. The original decomposed structure originates from a dev version of the framework [calliope](https://github.com/calliope-project/calliope), before the stable `v0.7` release. It comprises a reasonable example for how a model within an iterative solve could potentially look like.

## Approach

Generally, since the origin of the model is a Benders decomposition **main-model**, this example considers solving the given model using Gurobi with the "barrier method" (`Method = 2`) and with crossover deactivated (`Crossover = 0`), an approach that may be crucial to avoid zig-zag-ing behaviour of main-model solutions (e.g., during by applying a level-set method with a relaxed tolerance of the barrier method).

To compare the results, the model has been solved to optimality (as far as this can be guaranteed), by using Gurobi's simplex (with default settings), resulting in an objective value of `276997.16415941337`.

### Numerical problems

When running the model - and watching the solver log closely - the following warning message is being printed (not reported or returned in any form):

```console
Warning: Model contains large rhs
         Consider reformulating model or setting NumericFocus parameter
         to avoid numerical issues.
```

To account for that, the `NumericFocus` parameter was set to `3` (the highest setting), assuming that a further reformulation may not always be possible (either since it's a sub-model coming from a large and non-interactable energy system modeling framework, or it's about a main-problem with auto-generated cuts).

### Fallbacks

The code makes use of "fallback functions" to calculate primal and dual objective values. These make use of the implementation available in [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl), which is mostly uesd in situations in which a solver does not properly return the requested result. Instead of querying the solver, it takes the available variable values (either from primal or dual variables), as well as their coefficients in the respective objective functions, and "manually" calculates the resulting objective values.

## Results

### Solver log

```console
Gurobi Optimizer version 11.0.3 build v11.0.3rc0 (linux64 - "Ubuntu 24.04 LTS")

CPU model: Intel(R) Core(TM) i9-14900K, instruction set [SSE2|AVX|AVX2]
Thread count: 32 physical cores, 32 logical processors, using up to 32 threads

Optimize a model with 212 rows, 31 columns and 5015 nonzeros
Model fingerprint: 0x40fa2628
Coefficient statistics:
  Matrix range     [2e-10, 1e+07]
  Objective range  [1e+00, 1e+00]
  Bounds range     [1e-08, 1e+06]
  RHS range        [2e+05, 2e+12]
Warning: Model contains large matrix coefficient range
Warning: Model contains large rhs
Presolve removed 3 rows and 5 columns
Presolve time: 0.00s
Presolved: 28 rows, 237 columns, 5010 nonzeros
Ordering time: 0.00s

Barrier statistics:
 Free vars  : 2
 AA' NZ     : 3.780e+02
 Factor NZ  : 4.060e+02
 Factor Ops : 7.714e+03 (less than 1 second per iteration)
 Threads    : 1

                  Objective                Residual
Iter       Primal          Dual         Primal    Dual     Compl     Time
   0  -2.44109020e+14  1.44935442e+13  1.99e+05 2.28e+10  8.83e+12     0s
   1  -1.71999533e+14  1.95490538e+13  6.29e+04 4.30e+09  3.27e+12     0s
   2  -3.17156106e+13  1.05220101e+13  9.48e+03 5.69e+08  5.46e+11     0s
   3  -5.80434719e+12  4.08928194e+12  1.25e+03 5.97e+07  8.72e+10     0s
   4  -2.08271263e+12  1.41704970e+12  2.36e+02 5.92e+06  2.16e+10     0s
   5  -1.13080656e+12  1.61675291e+11  4.26e+01 2.02e+06  6.69e+09     0s
   6  -1.35717431e+11  1.37717911e+11  6.09e+00 2.01e+05  1.31e+09     0s
   7  -1.83791848e+10  1.38645110e+10  6.93e-01 2.06e+04  1.53e+08     0s
   8  -2.32714413e+09  1.41047781e+09  6.91e-02 2.04e+03  1.74e+07     0s
   9  -2.35231895e+08  1.42991092e+08  6.88e-03 2.03e+02  1.75e+06     0s
  10  -2.44265403e+07  1.60840933e+07  7.34e-04 2.18e+01  1.88e+05     0s
  11  -3.32792696e+06  3.35652170e+06  1.21e-04 3.52e+00  3.09e+04     0s
  12  -9.69936021e+05  1.43478076e+06  4.57e-05 3.48e-01  1.07e+04     0s
  13  -1.62770456e+05  6.00536034e+05  2.00e-05 3.45e-02  3.21e+03     0s
  14   1.07005693e+05  3.77224457e+05  1.08e-05 9.37e-03  1.12e+03     0s
  15   2.17173736e+05  3.22859108e+05  6.18e-06 3.25e-03  4.40e+02     0s
  16   2.50407178e+05  2.96875820e+05  2.72e-06 1.09e-03  1.94e+02     0s
  17   2.58911727e+05  2.83513238e+05  1.57e-05 3.01e-04  1.01e+02     0s
  18   2.69921330e+05  2.79326983e+05  8.33e-05 8.39e-05  3.48e+01     0s
  19   2.75281978e+05  2.78077061e+05  1.90e-05 2.55e-05  5.11e+00     0s
  20   2.75874612e+05  2.77830717e+05  1.28e-05 2.27e-05  1.11e+00     0s
  21   2.76017725e+05  2.77784773e+05  8.39e-07 7.78e-06  1.76e-01     0s
  22   2.76038404e+05  2.77775233e+05  1.53e-05 1.20e-05  2.53e-02     0s
  23   2.76041141e+05  2.77773745e+05  4.59e-06 7.63e-06  4.19e-03     0s
  24   2.76041518e+05  2.77773423e+05  3.68e-06 3.81e-06  1.03e-03     0s
  25   2.76041580e+05  2.77773335e+05  3.62e-06 7.63e-06  3.53e-04     0s
  26   2.76041609e+05  2.77773302e+05  4.75e-06 8.70e-06  4.36e-05     0s
  27   2.76041619e+05  2.77773300e+05  1.35e-05 8.23e-06  6.39e-06     0s
  28   2.76041623e+05  2.77773297e+05  2.15e-05 6.44e-06  2.20e-06     0s
  29   2.76041609e+05  2.77773299e+05  9.41e-06 4.65e-06  2.40e-07     0s
  30   2.76041617e+05  2.77773299e+05  8.45e-06 5.96e-06  5.33e-08     0s
  31   2.76041611e+05  2.77773300e+05  5.79e-06 6.32e-06  3.03e-08     0s
  32   2.76041615e+05  2.77773299e+05  3.02e-06 4.47e-06  1.32e-08     0s
  33   2.76041615e+05  2.77773301e+05  4.22e-06 4.89e-06  1.03e-08     0s
  34   2.76041614e+05  2.77773300e+05  5.31e-06 6.08e-06  8.40e-09     0s
  35   2.76041615e+05  2.77773299e+05  6.59e-06 4.41e-06  6.94e-09     0s
  36   2.76041614e+05  2.77773299e+05  5.29e-06 6.32e-06  3.48e-09     0s
  37   2.76041616e+05  2.77773298e+05  3.59e-06 5.84e-06  1.74e-09     0s
  38   2.76041616e+05  2.77773299e+05  4.58e-06 3.46e-06  1.25e-09     0s
  39   2.76041616e+05  2.77773299e+05  5.73e-06 4.41e-06  7.87e-10     0s
  40   2.76041614e+05  2.77773298e+05  6.82e-06 4.41e-06  4.98e-10     0s
  41   2.76041613e+05  2.77773299e+05  5.11e-06 4.02e-06  2.49e-10     0s
  42   2.76041614e+05  2.77773300e+05  6.76e-06 3.81e-06  1.82e-10     0s
  43   2.76041614e+05  2.77773300e+05  6.68e-06 4.41e-06  9.08e-11     0s
  44   2.76041613e+05  2.77773300e+05  8.46e-06 3.81e-06  6.11e-11     0s
  45   2.76041614e+05  2.77773300e+05  2.77e-06 4.89e-06  4.75e-11     0s
  46   2.76041614e+05  2.77773300e+05  2.60e-06 4.41e-06  3.63e-11     0s
  47   2.76041613e+05  2.77773300e+05  3.37e-06 4.05e-06  2.52e-11     0s
  48   2.76041615e+05  2.77773299e+05  4.85e-06 8.23e-06  1.80e-11     0s
  49   2.76041596e+05  2.77773298e+05  5.85e-06 7.63e-06  1.38e-11     0s
  50   2.76041599e+05  2.77773299e+05  8.47e-06 7.63e-06  9.51e-12     0s
  51   2.76041584e+05  2.77773298e+05  2.94e-06 2.86e-06  4.75e-12     0s
  52   2.76041568e+05  2.77773298e+05  4.00e-06 6.44e-06  3.50e-12     0s
  53   2.76041473e+05  2.77773298e+05  4.72e-06 3.81e-06  1.75e-12     0s
  54   2.76041865e+05  2.77773299e+05  4.88e-06 5.72e-06  1.36e-12     0s
  55   2.76042292e+05  2.77773299e+05  3.60e-06 4.41e-06  9.54e-13     0s
  56   2.76042210e+05  2.77773299e+05  2.90e-06 8.23e-06  4.85e-13     0s
  57   2.76042771e+05  2.77773299e+05  6.16e-06 5.48e-06  4.70e-13     0s
  58   2.76039130e+05  2.77773299e+05  5.94e-06 3.81e-06  3.39e-13     0s
  59   2.76041526e+05  2.77773300e+05  1.02e-05 6.08e-06  2.33e-13     0s
  60   2.76034836e+05  2.77773299e+05  6.13e-06 3.46e-06  1.17e-13     0s
  61   2.76035368e+05  2.77773299e+05  4.60e-06 3.81e-06  5.83e-14     0s
  62   2.75896018e+05  2.77773299e+05  5.28e-06 3.81e-06  2.91e-14     0s
  63   2.75913071e+05  2.77773300e+05  7.97e-06 3.58e-06  1.70e-14     0s
  64   2.75941139e+05  2.77773300e+05  6.34e-06 3.93e-06  1.56e-14     0s
  65   2.75534282e+05  2.77773300e+05  5.44e-06 4.41e-06  8.65e-15     0s
  66   2.75572864e+05  2.77773299e+05  5.70e-06 3.93e-06  4.32e-15     0s
  67   2.77329892e+05  2.77773299e+05  5.06e-06 6.20e-06  3.75e-15     0s
  68   2.77144877e+05  2.77773298e+05  6.42e-06 4.65e-06  3.18e-15     0s
  69   2.76916940e+05  2.77773299e+05  7.79e-06 8.23e-06  2.59e-15     0s
  70   2.76488186e+05  2.77773299e+05  8.88e-06 4.65e-06  1.30e-15     0s
  71   2.76389305e+05  2.77773300e+05  8.95e-06 4.17e-06  9.76e-16     0s
  72   2.76554240e+05  2.77773299e+05  4.47e-06 3.83e-06  4.88e-16     0s
  73   2.76350697e+05  2.77773299e+05  7.32e-06 4.41e-06  2.65e-16     0s
  74   2.76103058e+05  2.77773299e+05  1.72e-06 6.44e-06  1.32e-16     0s
  75   2.75889230e+05  2.77773299e+05  3.60e-06 4.17e-06  1.24e-16     0s
  76   2.75943986e+05  2.77773299e+05  4.03e-06 6.20e-06  6.24e-17     0s
  77   2.75650624e+05  2.77773298e+05  4.37e-06 5.84e-06  4.63e-17     0s
  78   2.75832344e+05  2.77773298e+05  4.67e-06 7.63e-06  3.78e-17     0s
  79   2.75843409e+05  2.77773299e+05  8.90e-06 6.44e-06  3.64e-17     0s

Barrier solved model in 79 iterations and 0.01 seconds (0.06 work units)
Optimal objective 2.76103058e+05
```

### Claimed feasibility / optimality

Common status information that a user might check:

```julia
primal_status(model)       # FEASIBLE_POINT::ResultStatusCode = 1
dual_status(model)         # FEASIBLE_POINT::ResultStatusCode = 1
termination_status(model)  # OPTIMAL::TerminationStatusCode = 1
has_values(model)          # true
has_duals(model)           # true
```

### Irregular primal objective value

```julia
objective_value(model)                        # 276103.05802923767
objective_value(model) >= 276997.16415941337  # false
```

### Unaccessible dual objective value

```julia
dual_objective_value(model)
# ERROR: Gurobi Error 10005: Unable to retrieve attribute 'ObjBound'
```

### Fallback objectives

```julia
get_fb_primal_obj(model)  # 277773.29949693667
get_fb_dual_obj(model)    # 140570.4147468655
```

### Dual violation

```julia
MOI.get(model, Gurobi.ModelAttribute("DualVio"))  # 0.24542313747301034
```
