# phd-paper-model-collection

Collection of example models used in the paper "currently without a name" submitted to "the international currently nonexisting".

## Miscellaneous

### Versions

Versions for specific packages, solvers, etc. can matter. Where applicable, the code is accompanied by `Project.toml` and `Manifest.toml` files.

Versions of solvers are verified by running

```julia
using JuMP
using Gurobi: Gurobi
using HiGHS: HiGHS

model = Model(HiGHS.Optimizer)
@variable(model, x >= 0)
@objective(model, Min, x)
optimize!(model)

model = Model(Gurobi.Optimizer)
@variable(model, x >= 0)
@objective(model, Min, x)
optimize!(model)
```

which can be important since the compat entries (e.g., [HiGHS.jl](https://github.com/jump-dev/HiGHS.jl/blob/bdb78995a11b5146099de52d1c730d1904b2493a/Project.toml)) may allow for older versions of the underlying solvers, even if the Julia wrapper package is up to date.

### Model creation

Models are created - if not stated otherwise - using [JuMP](https://github.com/jump-dev/JuMP.jl).

### Formatting

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle)

All files are formatted using [JuliaFormatter](https://github.com/domluna/JuliaFormatter.jl) based on the style ["Blue"](https://github.com/JuliaDiff/BlueStyle), by running

```julia
using JuliaFormatter

format(".", BlueStyle())
```
