# 008

Running:

```shell
julia --project=v192 code.jl
julia --project=v193 code.jl
julia --project=v1130 code.jl
```

| env | `HiGHS.jl` | `HiGHS` | solve [s] | get dual obj. [ms] | get dual obj. [MB] | get duals [ms] | get duals [MB] | 
| --- | --- | --- | --- | --- | --- | --- | --- |
| v192 | 1.9.2 | 1.7.0 | 13.6099 | 91462.5 | 4.3 | 83.3 | 3.7 |
| v193 | v1.9.3 | v1.7.0 | 14.74 | 1.2 | 3.0 | 4.4 | 3.7 |
| v1130 | v1.13.0 | v1.9.0 | 10.04 | 0.9 | 3.0 | 11.2 | 3.7 |


Links:
https://github.com/jump-dev/HiGHS.jl/issues/223
https://github.com/jump-dev/HiGHS.jl/issues/207
https://github.com/jump-dev/HiGHS.jl/pull/229
https://github.com/ERGO-Code/HiGHS/pull/1978

Link to TimerOutputs
