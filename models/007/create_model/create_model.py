import calliope


d = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
for m in range(12):
    model = calliope.examples.national_scale(
        override_dict={
            "config.init.time_subset": ["2005-01-01", f"2005-{(m + 1):02d}-{d[m]}"],
            "config.solve.solver": "gurobi",
        }
    )
    model.build(backend="gurobi")
    model.backend._instance.write(f"models/{len(model.inputs.timesteps)}.mps")
