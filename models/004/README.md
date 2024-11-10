# Model 004

This showcases how [Gurobi's `PreDual` parameter](https://docs.gurobi.com/projects/optimizer/en/current/reference/parameters.html#predual) influences the extraction of objective values, which might interfere with proper calculation of

- per-iteration objective bounds (as part of the main-problem), or 
- the "offset" inclusion during the calculation of cuts obtained from a sub-model.

## Details

The model is the same used in [model 003](../003/README.md), which leads to the same target optimal objective value of `276997.16415941337`. Note that similarly the model is again being solved with `NumericFocus = 3`, and that the same fallback functions are used.

## Approach

The model is solved twice, with varying settings for `PreDual`, which controls whether the passed primal is solved, or whether it is instead converted to a dual representative beforehand.

## Results

Given that directly querying the "optimal" dual objective value is not possible (since accessing Gurobi's `ObjBound` attribute fails with a `Gurobi Error 10005`) the following notation is used:

- $O$ for the "true" optimal objective value
- $P$ for the primal objective value
- $P_{fb}$ for the primal objective value, calculated using the fallback function
- $D_{fb}$ for the dual objective value, calculated using the fallback function

With that, the results can be summarized:

- **`PreDual` = 0**: $D_{fb} < O < P_{fb} = P$ 
- **`PreDual` = 1**: $D_{fb} < P < O < P_{fb}$ 

Note that for the case **`PreDual` = 1** the fallback dual objective value is basically meaningless. This entails that without explicit knowledge of `PreDual` (the default is "chose", requiring it to be set to guarantee knowledge of its value) the only usable information lies in the statement $O < P_{fb}$, giving an upper bound on the true optimum. However, note that the fallback might be considerably slower / more memory consuming to calculate than "just querying" the original objective value.

### `PreDual` = 0

#### Objectives

```julia
objective_value(model)            # 276997.2389653433
get_fb_obj(model; obj = :primal)  # 276997.2389653433
get_fb_obj(model; obj = :dual)    # 276997.02234643674
```

#### Solver log

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
Presolve removed 10 rows and 14 columns
Presolve time: 0.00s
Presolved: 202 rows, 17 columns, 3360 nonzeros
Ordering time: 0.00s

Barrier statistics:
 AA' NZ     : 2.030e+04
 Factor NZ  : 2.050e+04
 Factor Ops : 2.768e+06 (less than 1 second per iteration)
 Threads    : 32

                  Objective                Residual
Iter       Primal          Dual         Primal    Dual     Compl     Time
   0   1.70059926e+07 -6.98246336e+11  2.19e+07 0.00e+00  1.96e+10     0s
   1   1.73149423e+07 -2.12535194e+11  5.44e+06 7.22e+01  3.68e+09     0s
   2   1.74765969e+07 -4.83537568e+10  1.37e+05 1.08e+01  5.39e+08     0s
   3   1.72602044e+07 -5.26942079e+09  0.00e+00 1.08e+00  5.46e+07     0s
   4   1.52908411e+07 -5.35476638e+08  0.00e+00 1.08e-01  5.53e+06     0s
   5   6.53663363e+06 -5.36532804e+07  0.00e+00 1.08e-02  5.71e+05     0s
   6   1.54495674e+06 -5.36456127e+06  0.00e+00 1.07e-03  6.16e+04     0s
   7   9.79985531e+05 -6.20636979e+05  0.00e+00 1.27e-04  1.21e+04     0s
   8   5.85491755e+05  1.02956083e+05  0.00e+00 1.02e-17  2.60e+03     0s
   9   4.04571193e+05  2.04891403e+05  0.00e+00 3.14e-18  9.54e+02     0s
  10   3.12644077e+05  2.43751497e+05  0.00e+00 3.47e-18  3.06e+02     0s
  11   2.86773410e+05  2.68596311e+05  0.00e+00 3.06e-18  7.85e+01     0s
  12   2.79140274e+05  2.73636397e+05  0.00e+00 2.08e-17  2.36e+01     0s
  13   2.77674608e+05  2.75476573e+05  0.00e+00 3.47e-18  9.39e+00     0s
  14   2.77352474e+05  2.76414003e+05  0.00e+00 1.12e-17  4.00e+00     0s
  15   2.77080616e+05  2.76865404e+05  0.00e+00 1.37e-16  9.17e-01     0s
  16   2.77019733e+05  2.76945848e+05  0.00e+00 4.99e-17  3.15e-01     0s
  17   2.77003556e+05  2.76987297e+05  0.00e+00 2.78e-17  6.92e-02     0s
  18   2.76999480e+05  2.76993068e+05  0.00e+00 2.45e-17  2.73e-02     0s
  19   2.76998157e+05  2.76995865e+05  0.00e+00 1.60e-17  9.75e-03     0s
  20   2.76997460e+05  2.76996440e+05  0.00e+00 1.34e-17  4.35e-03     0s
  21   2.76997239e+05  2.76997016e+05  0.00e+00 1.39e-17  9.49e-04     0s

Barrier solved model in 21 iterations and 0.04 seconds (0.02 work units)
Optimal objective 2.76997239e+05
```

### `PreDual` = 1

#### Objectives

```julia
objective_value(model)            # 276041.57983460044
get_fb_obj(model; obj = :primal)  # 277773.33495775046
get_fb_obj(model; obj = :dual)    # -51195.53690508625
```

#### Solver log

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

Barrier solved model in 25 iterations and 0.00 seconds (0.02 work units)
Optimal objective 2.76041580e+05
```
