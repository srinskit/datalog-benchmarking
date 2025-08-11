import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

import matplotlib as mpl

# Use the PGF backend
mpl.use('pgf')

# Optional: Configure global settings for LaTeX look
mpl.rcParams.update({
    "pgf.texsystem": "pdflatex",  # or "xelatex", "lualatex"
    "font.family": "serif",       # use serif fonts
    "text.usetex": True,          # use LaTeX for all text
    "pgf.rcfonts": False,         # do not setup fonts from rc parameters
})

# Output settings
output_path = "plan_variance"

# Load the CSV file
file_path = "data.csv"  # Replace with your actual file
df = pd.read_csv(file_path)

# Replace 'x' with 600
df.replace("x", 600, inplace=True)
for col in ["flowlog_o", "flowlog", "souffle_c"]:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Melt the data
df_melted = df.melt(
    id_vars=["program"],
    value_vars=["souffle_c", "flowlog", "flowlog_o"],
    var_name="engine",
    value_name="runtime",
)
df_melted["engine"] = pd.Categorical(
    df_melted["engine"], categories=["flowlog_o", "flowlog", "souffle_c"], ordered=True
)

# Color map
engine_colors = {"flowlog_o": "red", "flowlog": "blue", "souffle_c": "black"}
median_color = "darkgreen"

# Program and engine labels
program_titles = {
    "ddisasm": "DDISASM",
    "doop": "DOOP",
    "galen": "Galen"
}
engine_labels = ["FlowLog\n(optimized)", "FlowLog", "Souffle\n(compiled)"]
captions = ["DDISASM (z3) on 30 orders", "DOOP (batik) on 43 orders", "Galen (galen) on 18 orders"]
# Unique programs
programs = df["program"].unique()
num_programs = len(programs)

font_label, font_tick, font_legend, font_caption = [30, 30, 22, 26]

# Create subplots with larger height
fig, axes = plt.subplots(1, num_programs, figsize=(8 * num_programs, 6), sharey=False)

# Plot
for idx, program in enumerate(programs):
    ax = axes[idx]
    program_subset = df_melted[df_melted["program"] == program].copy()

    for engine in ["flowlog_o", "flowlog", "souffle_c"]:
        engine_data = program_subset[program_subset["engine"] == engine]
        x_pos = np.full(len(engine_data), ["flowlog_o", "flowlog", "souffle_c"].index(engine), dtype=float)
        x_pos += np.random.uniform(-0.25, 0.25, size=len(engine_data))
        y_pos = engine_data["runtime"]

        timeout_mask = engine_data["runtime"] >= 599
        normal_mask = ~timeout_mask

        ax.scatter(
            x_pos[normal_mask], y_pos[normal_mask],
            marker="o", facecolors="none",
            edgecolors=engine_colors[engine], linewidths=2.5, s=120
        )
        ax.scatter(
            x_pos[timeout_mask], y_pos[timeout_mask],
            marker="x", color=engine_colors[engine],
            linewidths=2.5, s=120
        )

    ax.set_yscale("log")
    ax.set_ylim(10, 1200)

    # Vertical dotted lines
    for vline in [0.5, 1.5]:
        ax.axvline(x=vline, color='gray', linestyle=':', linewidth=2)

    # Plot medians
    for i, engine in enumerate(["flowlog_o", "flowlog", "souffle_c"]):
        engine_data = program_subset[program_subset["engine"] == engine]["runtime"]
        if not engine_data.empty:
            median_val = engine_data.median()
            ax.hlines(
                y=median_val, xmin=i - 0.4, xmax=i + 0.4,
                colors=median_color, linestyles="--", linewidth=4
            )
            ax.text(
                i, 800,
                "M = {:.1f}s".format(median_val),
                fontsize=font_legend, fontweight="bold",
                color=median_color, ha='center'
            )

    ax.set_xticks([0, 1, 2])
    ax.set_xticklabels(engine_labels, fontsize=font_label)

    # REMOVE individual x labels
    ax.set_xlabel("")
    
    if idx == 0:
        ax.set_ylabel("Runtime (s, log scale)", fontsize=font_label, labelpad=20)
    else:
        ax.set_ylabel("")

    # Increase font size for x and y ticks
    ax.tick_params(axis='y', which='major', labelsize=font_tick)
    ax.tick_params(axis='x', which='major', labelsize=22)
    ax.text(0.5, -0.25, f"\\textbf{{({chr(97+idx)}) {captions[idx]}}}",
                transform=ax.transAxes, ha='center', va='top', fontsize=font_caption)

plt.savefig(f"{output_path}.pgf", bbox_inches='tight', pad_inches=0.2)
plt.savefig(f"{output_path}.png", bbox_inches='tight', pad_inches=0.2)
plt.close()

print(f"Plot saved to {output_path}")
