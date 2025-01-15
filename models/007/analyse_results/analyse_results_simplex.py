import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ================================================================
WSA = "Warmstart-able"
TC = "Test Case"
TIME = "avg_sec"
ITER = "avg_iter"

modes = ["primal", "jump_conic_dual", "general"]
# ================================================================

# ================================================================
df_stats = pd.read_csv("out/model_stats.csv")
df_stats = df_stats.loc[df_stats.version == "original"]
df_stats = df_stats.reset_index(drop=True)

df_results = pd.read_csv("out/results_2025-01-14T223855.423.csv")
df_results = df_results.loc[df_results.objective != -1]
df_results["model"] = df_results["model"].apply(lambda s: df_stats.index[df_stats.model == s][0])
df_results[WSA] = False
df_results[TC] = ""
# ================================================================

# [01] Gurobi simplex, PreDual=0.
res_01 = df_results.loc[(df_results.solver == "gurobi") & (df_results.test_case.isin([1, 3]))]
sel = [(res_01["mode"] == m) & (res_01.test_case == tc) for m in modes for tc in [1, 3]]
res_01.loc[sel[0], [WSA, TC]] = [False, "primal (RAW)"]
res_01.loc[sel[1], [WSA, TC]] = [True, "dual (RAW)"]
res_01.loc[sel[2], [WSA, TC]] = [True, "primal (JCD)"]
res_01.loc[sel[3], [WSA, TC]] = [False, "dual (JCD)"]
res_01.loc[sel[4], [WSA, TC]] = [True, "primal (GEN)"]
res_01.loc[sel[5], [WSA, TC]] = [False, "dual (GEN)"]
res_01 = res_01.sort_values(by=TC, ascending=False)

# [02] Gurobi simplex, PreDual=1.
res_02 = df_results.loc[(df_results.solver == "gurobi") & (df_results.test_case.isin([2, 4]))]
sel = [(res_02["mode"] == m) & (res_02.test_case == tc) for m in modes for tc in [2, 4]]
res_02.loc[sel[0], [WSA, TC]] = [True, "primal (RAW)"]
res_02.loc[sel[1], [WSA, TC]] = [False, "dual (RAW)"]
res_02.loc[sel[2], [WSA, TC]] = [False, "primal (JCD)"]
res_02.loc[sel[3], [WSA, TC]] = [True, "dual (JCD)"]
res_02.loc[sel[4], [WSA, TC]] = [False, "primal (GEN)"]
res_02.loc[sel[5], [WSA, TC]] = [True, "dual (GEN)"]
res_02 = res_02.sort_values(by=TC, ascending=False)

# [03] HiGHS simplex.
res_03 = df_results.loc[(df_results.solver == "highs") & (df_results.test_case.isin([2, 4]))]
sel = [(res_03["mode"] == m) & (res_03.test_case == tc) for m in modes for tc in [2, 4]]
res_03.loc[sel[0], [WSA, TC]] = [True, "dual (RAW)"]
res_03.loc[sel[1], [WSA, TC]] = [False, "primal (RAW)"]
res_03.loc[sel[2], [WSA, TC]] = [False, "dual (JCD)"]
res_03.loc[sel[3], [WSA, TC]] = [True, "primal (JCD)"]
res_03.loc[sel[4], [WSA, TC]] = [False, "dual (GEN)"]
res_03.loc[sel[5], [WSA, TC]] = [True, "primal (GEN)"]
res_03 = res_03.sort_values(by=TC, ascending=False)

# Create SIMPLEX plot(s).
fig, axes = plt.subplots(3, 2, figsize=(13, 13))
kw = dict(hue=TC, style=WSA, dashes={False: (2, 2), True: ""}, markers={False: "X", True: "o"})
sns.lineplot(ax=axes[0, 0], data=res_01, x=df_stats.loc[res_01.model, "nonzeros"].values, y=TIME, **kw)
sns.lineplot(ax=axes[0, 1], data=res_01, x=df_stats.loc[res_01.model, "nonzeros"].values, y=ITER, **kw)
sns.lineplot(ax=axes[1, 0], data=res_02, x=df_stats.loc[res_02.model, "nonzeros"].values, y=TIME, **kw)
sns.lineplot(ax=axes[1, 1], data=res_02, x=df_stats.loc[res_02.model, "nonzeros"].values, y=ITER, **kw)
sns.lineplot(ax=axes[2, 0], data=res_03, x=df_stats.loc[res_03.model, "nonzeros"].values, y=TIME, **kw)
sns.lineplot(ax=axes[2, 1], data=res_03, x=df_stats.loc[res_03.model, "nonzeros"].values, y=ITER, **kw)

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
fig.legend(handles[:-3], labels[:-3], loc="upper center", bbox_to_anchor=(0.5, 0.035), fontsize=12, ncol=10)
fig.legend(handles[-3:], labels[-3:], loc="upper center", bbox_to_anchor=(0.5, 0.065), fontsize=12, ncol=10)

# Add titles.
fig.suptitle("Average solve complexity of different model formulations", fontsize=20)
fig.text(0.5, 0.930, "Gurobi 11.0.3  ~  simplex (PreDual=0)", ha="center", fontsize=14, fontweight="bold")
fig.text(0.5, 0.640, "Gurobi 11.0.3  ~  simplex (PreDual=1)", ha="center", fontsize=14, fontweight="bold")
fig.text(0.5, 0.350, "HiGHS 1.8.0  ~  simplex", ha="center", fontsize=14, fontweight="bold")

# General styling.
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.2)
plt.tight_layout(rect=(0.0, 0.07, 1.0, 0.98), h_pad=2.0, w_pad=2.0)

# Show / save.
plt.savefig("out/analysis_plot_simplex.png")
plt.savefig("out/analysis_plot_simplex.svg")
plt.show()
