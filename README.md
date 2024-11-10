# phd-paper-model-collection

Collection of example models used in the paper "currently without a name" submitted to "the international currently nonexisting".

## Miscellaneous

### Versions

Versions for specific packages, solvers, etc. can matter. Where applicable, the code is accompanied by `Project.toml` and `Manifest.toml` files.

### Model creation

Models are created - if not stated otherwise - using [JuMP](https://github.com/jump-dev/JuMP.jl).

### Formatting

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle)

All files are formatted using [JuliaFormatter](https://github.com/domluna/JuliaFormatter.jl) based on the style ["Blue"](https://github.com/JuliaDiff/BlueStyle), by running

```julia
using JuliaFormatter

format(".", BlueStyle())
```
