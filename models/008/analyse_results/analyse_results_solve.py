import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


df = pd.read_csv("out/results.csv")
df["overhead"] = df["total_time"] - df["solve_time"] - df["get_dual_obj_time"] - df["get_duals_time"]

dft = df[["highs", "solve_time", "overhead"]]
dft = dft.rename(columns={"solve_time": "solve"})

fig, ax = plt.subplots(figsize=(12, 4))

# Plot time.
dft_melted = dft.melt(id_vars=["highs"], value_vars=["solve", "overhead"], var_name="Type", value_name="Time")
dft_pivot = dft_melted.pivot_table(index="highs", columns="Type", values="Time", aggfunc="sum").fillna(0)
dft_pivot.plot(kind="bar", stacked=True, ax=ax)
ax.set_xlabel("HiGHS")
ax.set_ylabel("time [s]")
ax.tick_params(axis="x", rotation=0)

# General styling.
# fig.suptitle("Evolution of solve time", fontsize=20)
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.2)
plt.tight_layout(h_pad=3.5, w_pad=2.0)

# Show / save.
plt.savefig("out/analysis_008_solve.svg")
plt.show()
