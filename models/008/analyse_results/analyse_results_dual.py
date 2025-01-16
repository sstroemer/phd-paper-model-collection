import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


df = pd.read_csv("out/results.csv")

dft = df[["highsjl", "get_dual_obj_time", "get_duals_time"]]
dft = dft.rename(columns={"get_dual_obj_time": "objective value", "get_duals_time": "variables"})
dfm = df[["highsjl", "get_dual_obj_alloc", "get_duals_alloc"]]
dfm = dft.rename(columns={"get_dual_obj_alloc": "objective value", "get_duals_alloc": "variables"})

fig, axes = plt.subplots(1, 2, figsize=(14, 7))

# Plot time.
sns.barplot(
    data=dft.melt(id_vars="highsjl", var_name="Type", value_name="Time"), x="highsjl", y="Time", hue="Type", ax=axes[0]
)
axes[0].set_xlabel("HiGHS.jl")
axes[0].set_ylabel("time [s]")
axes[0].set_yscale("log")
axes[0].tick_params(axis="x", rotation=0)

# Plot memory.
sns.barplot(
    data=dfm.melt(id_vars="highsjl", var_name="Type", value_name="Allocations"),
    x="highsjl",
    y="Allocations",
    hue="Type",
    ax=axes[1],
)
axes[1].set_xlabel("HiGHS.jl")
axes[1].set_ylabel("allocations [MB]")
axes[1].set_yscale("log")
axes[1].tick_params(axis="x", rotation=0)

# Second subplot
# df.plot(kind="bar", x="highs", y="solve_time", ax=axes[1])
# axes[1].set_title("solve_time over highs")
# axes[1].set_xlabel("highs")
# axes[1].set_ylabel("solve_time")

# General styling.
# fig.suptitle("Complexity of dual result extraction", fontsize=20)
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.2)
plt.tight_layout(h_pad=3.5, w_pad=2.0)

# Show / save.
plt.savefig("out/analysis_008_dual.svg")
plt.show()
