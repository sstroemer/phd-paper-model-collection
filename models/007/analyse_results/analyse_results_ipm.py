import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ================================================================
TC = "Test Case"
ALGO = "Algorithm"
TIME = "avg_sec"
ITER = "avg_iter"

modes = ["primal", "jump_conic_dual", "general"]
# ================================================================

# ================================================================
df_stats = pd.read_csv("out/model_stats.csv")
df_stats = df_stats.loc[df_stats.version == "original"]
df_stats = df_stats.reset_index(drop=True)

df_results = pd.read_csv("out/results.csv")
df_results = df_results.loc[df_results.objective != -1]
df_results["model"] = df_results["model"].apply(lambda s: df_stats.index[df_stats.model == s][0])
df_results[TC] = ""
df_results[ALGO] = ""
# ================================================================

# [01] Gurobi "barrier", PreDual=0.
res_01 = df_results.loc[(df_results.solver == "gurobi") & (df_results.test_case.isin([5, 7]))]
sel = [(res_01["mode"] == m) & (res_01.test_case == tc) for m in modes for tc in [5, 7]]
res_01.loc[sel[0], [ALGO, TC]] = ["default", "RAW"]
res_01.loc[sel[1], [ALGO, TC]] = ["homogeneous", "RAW"]
res_01.loc[sel[2], [ALGO, TC]] = ["default", "JCD"]
res_01.loc[sel[3], [ALGO, TC]] = ["homogeneous", "JCD"]
res_01.loc[sel[4], [ALGO, TC]] = ["default", "GEN"]
res_01.loc[sel[5], [ALGO, TC]] = ["homogeneous", "GEN"]
res_01 = res_01.sort_values(by=TC, ascending=False)

# [02] Gurobi "barrier", PreDual=1.
res_02 = df_results.loc[(df_results.solver == "gurobi") & (df_results.test_case.isin([6, 8]))]
sel = [(res_02["mode"] == m) & (res_02.test_case == tc) for m in modes for tc in [6, 8]]
res_02.loc[sel[0], [ALGO, TC]] = ["default", "dual (RAW)"]
res_02.loc[sel[1], [ALGO, TC]] = ["homogeneous", "dual (RAW)"]
res_02.loc[sel[2], [ALGO, TC]] = ["default", "dual (JCD)"]
res_02.loc[sel[3], [ALGO, TC]] = ["homogeneous", "dual (JCD)"]
res_02.loc[sel[4], [ALGO, TC]] = ["default", "dual (GEN)"]
res_02.loc[sel[5], [ALGO, TC]] = ["homogeneous", "dual (GEN)"]
res_02 = res_02.sort_values(by=TC, ascending=False)

# [03] HiGHS "ipm".
res_03 = df_results.loc[(df_results.solver == "highs") & (df_results.test_case.isin([5]))]
sel = [(res_03["mode"] == m) & (res_03.test_case == tc) for m in modes for tc in [5]]
res_03.loc[sel[0], TC] = "RAW"
res_03.loc[sel[1], TC] = "JCD"
res_03.loc[sel[2], TC] = "GEN"
res_03 = res_03.sort_values(by=TC, ascending=False)

# Create IPM plot(s).
fig, axes = plt.subplots(3, 2, figsize=(13, 13))
kw = dict(style=ALGO, dashes={"homogeneous": (1, 2), "default": ""}, markers={"homogeneous": "X", "default": "o"})
sns.lineplot(ax=axes[0, 0], data=res_01, x=df_stats.loc[res_01.model, "nonzeros"].values, y=TIME, hue=TC, **kw)
sns.lineplot(ax=axes[0, 1], data=res_01, x=df_stats.loc[res_01.model, "nonzeros"].values, y=ITER, hue=TC, **kw)
sns.lineplot(ax=axes[1, 0], data=res_02, x=df_stats.loc[res_02.model, "nonzeros"].values, y=TIME, hue=TC, **kw)
sns.lineplot(ax=axes[1, 1], data=res_02, x=df_stats.loc[res_02.model, "nonzeros"].values, y=ITER, hue=TC, **kw)
kw = dict(y=TIME, hue=TC, style=True, markers=True)
sns.lineplot(ax=axes[2, 0], data=res_03, x=df_stats.loc[res_03.model, "nonzeros"].values, **kw)
sns.lineplot(ax=axes[2, 1], data=res_03, x=df_stats.loc[res_03.model, "nonzeros"].values, **kw)

# Configure axes.
x_min = df_stats.loc[df_results.model.min(), "nonzeros"] * 0.75
x_max = df_stats.loc[df_results.model.max(), "nonzeros"] * 1.05
for i in range(3):
    for j in range(2):
        # Style axes.
        ax: plt.Axes = axes[i, j]
        ax.set_xlim(x_min, x_max)
        ax.set_xlabel("nonzeros in original model", fontsize=16)
        ax.set_ylabel("avg. time [s]" if j == 0 else "avg. iterations", fontsize=16)
        ax.ticklabel_format(style="sci", axis="both", scilimits=(0, 3))
        ax.legend().set_visible(False)

# Place legend below the entire plot area.
handles, labels = axes[0, 0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.5, 0.925), fontsize=11, ncol=10)
handles, labels = axes[1, 0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.5, 0.615), fontsize=11, ncol=10)
handles, labels = axes[2, 0].get_legend_handles_labels()
fig.legend(handles[:-1], labels[:-1], loc="upper center", bbox_to_anchor=(0.5, 0.305), fontsize=11, ncol=10)

# Add titles.
fig.suptitle("Average solve complexity of different model formulations", fontsize=20)
fig.text(0.5, 0.925, "Gurobi 11.0.3  ~  barrier (PreDual=0)", ha="center", fontsize=14, fontweight="bold")
fig.text(0.5, 0.615, "Gurobi 11.0.3  ~  barrier (PreDual=1)", ha="center", fontsize=14, fontweight="bold")
fig.text(0.5, 0.305, "HiGHS 1.8.0  ~  ipm", ha="center", fontsize=14, fontweight="bold")

# General styling.
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.2)
plt.tight_layout(rect=(0.0, 0.0, 1.0, 0.945), h_pad=3.5, w_pad=2.0)

# Show / save.
plt.savefig("out/analysis_plot_ipm.png")
plt.savefig("out/analysis_plot_ipm.svg")
plt.show()
