#!/usr/bin/python3
# python plot.py Bipartite_netflix_4* Galen_Galen_64* DOOP_biojava_64*

import matplotlib
import pandas as pd
import re
import argparse
import shutil
import sys

# =============================================================================
# DISPLAY PARAMETERS - Modify these to customize the plot appearance
# =============================================================================

# Figure settings
FIG_SIZES = [34, 10]  # [width, height] in inches
METRICS = "cm"  # "c"=CPU, "m"=Memory, "r"=IO Reads

# Font sizes
FONT_LABEL = 36
FONT_TICK = 30
FONT_LEGEND = 28
FONT_CAPTION = 32

# Line settings
LINE_WIDTH = 7

# Data processing
INTERVALS = [2, 3, 2]  # Time interval grouping per benchmark
TIMECLIPS = [-1, 80, -1]  # Max time to display (-1 = no limit)
MEMCLIPS = None  # Max memory to display (None = no limit)
SKIP_ENGINES = "i"  # Engine keys to skip ("i" = souffle-intptr)
NO_LEGEND = False

# Captions for each benchmark
CAPTIONS = [
    "Bipartite (netflix), 4 threads",
    "Galen (galen), 64 threads",
    "DOOP (biojava), 64 threads",
]

# =============================================================================

# Require LaTeX to be available
if not shutil.which("pdflatex"):
    print("Error: pdflatex not found. Please install LaTeX.")
    sys.exit(1)

matplotlib.use("pgf")

import matplotlib.pyplot as plt

# Configure LaTeX settings
plt.rcParams.update(
    {
        "pgf.texsystem": "pdflatex",
        "font.family": "serif",
        "text.usetex": True,
        "pgf.rcfonts": False,
    }
)

def pretty_parse(log_files):
    seq = [
        ("Flowlog", "blue", "flowlog", "f", "-"),
        ("Flowlog", "blue", "eclair", "f", "-"),
        ("Souf. (cmp.)", "black", "souffle-cmpl", "s", "--"),
        ("Souf. (intp.)", "gray", "souffle-intptr", "i", "--"),
        ("RecStep", "orange", "recstep", "r", ":"),
        ("DDlog", "red", "ddlog", "d", "-."),
    ]

    workers_set = set()
    dataset_set = set()
    program_set = set()

    engine = None
    workers = None
    dataset = None
    program = None

    log_map = {}

    for file in log_files:
        features = re.split(r"[/_.]", file.name)
        engine = features[-2]
        workers = features[-3]
        dataset = features[-4]
        program = features[-5]

        workers_set.add(workers)
        dataset_set.add(dataset)
        program_set.add(program)

        error_found = True
        if engine in log_map:
            print("Error: ensure only one log file per engine is supplied")
        elif len(workers_set) != 1:
            print("Error: ensure only one set of workers are compared")
        elif len(dataset_set) != 1:
            print("Error: ensure only one dataset is compared")
        elif len(program_set) != 1:
            print("Error: ensure only one program is compared")
        else:
            log_map[engine] = file
            error_found = False

        if error_found:
            print("Files:\n" + "\n".join([file.name for file in log_files]))
            exit(1)

    result = []

    for label, color, engine, engine_key, line_type in seq:
        if engine in log_map:
            result.append((label, color, log_map[engine], engine_key, line_type))

    return result, program, dataset, int(workers)


def plot_run():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "logs",
        metavar="file",
        type=argparse.FileType("r"),
        help="Path to log files of runs",
        nargs="+",
    )

    args = parser.parse_args()
    files = args.logs

    # Use parameters from top of file
    metrics = METRICS
    intervals = INTERVALS
    pretty = True
    memclips = MEMCLIPS
    timeclips = TIMECLIPS
    skip_engines = SKIP_ENGINES
    no_legend = NO_LEGEND
    fig_sizes = FIG_SIZES

    font_label, font_tick, font_legend, font_caption = [FONT_LABEL, FONT_TICK, FONT_LEGEND, FONT_CAPTION]
    line_width = LINE_WIDTH

    # Organize given log files by programs
    run_organizer = {}

    for file in files:
        features = re.split(r"[/_.]", file.name)

        if features[-1] == "log":
            bucket = "_".join(features[-5:-2])

            if bucket in run_organizer:
                run_organizer[bucket].append(file)
            else:
                run_organizer[bucket] = [file]

    run_cnt = len(run_organizer)
    chart_cnt = len(metrics)
    fig, run_graphs = plt.subplots(
        chart_cnt, run_cnt, figsize=(fig_sizes[0], fig_sizes[1])
    )

    if chart_cnt == 1:
        run_graphs = [run_graphs]

    if run_cnt == 1:
        run_graphs = [[ax] for ax in run_graphs]

    # Transpose to one run's chart per row
    run_graphs = [[run_graphs[j][i] for j in range(chart_cnt)] for i in range(run_cnt)]

    captions = CAPTIONS

    for run_id, (group, graph_ax) in enumerate(zip(run_organizer, run_graphs)):
        log_files = run_organizer[group]
        runs, program, dataset, workers = pretty_parse(log_files)
        priority = len(log_files)

        for label, clr, file, engine_key, line_type in runs:
            if skip_engines is not None and engine_key in skip_engines:
                continue

            data = pd.read_csv(file)

            # Cleanup data- intervals, timeclip, memclip
            if True:
                interval = -1

                if intervals is not None:
                    if len(intervals) == 1:
                        interval = intervals[0]
                    elif len(intervals) == run_cnt:
                        interval = intervals[run_id]
                    else:
                        print(
                            "[error] specify interval for all graphs, once, or never."
                        )
                        exit(1)

                if interval is not None and interval > 0:
                    data["Time"] = (data["Time"] // interval) * interval
                    df_resampled = data.groupby("Time", as_index=False).median()
                    data = df_resampled

                timeclip = -1

                if timeclips is not None:
                    if len(timeclips) == 1:
                        timeclip = timeclips[0]
                    elif len(timeclips) == run_cnt:
                        timeclip = timeclips[run_id]
                    else:
                        print(
                            "[error] specify timeclip for all graphs, once, or never."
                        )
                        exit(1)

                if timeclip > 0:
                    data = data[data["Time"] <= timeclip].copy()

                data["MEM Usage"] = data["MEM Usage"].div(1024.0 * 1024.0 * 1024.0)

                if pretty:
                    data["CPU Percent"] = (
                        data["CPU Percent"].div(workers).clip(lower=0, upper=100)
                    )

                memclip = -1

                if memclips is not None:
                    if len(memclips) == 1:
                        memclip = memclips[0]
                    elif len(memclips) == run_cnt:
                        memclip = memclips[run_id]
                    else:
                        print("[error] specify memclip for all graphs, once, or never.")
                        exit(1)

                if memclip > 0:
                    data["MEM Usage"] = data["MEM Usage"].clip(lower=0, upper=memclip)

            # Main plot
            for i, (g, ax) in enumerate(zip(metrics, graph_ax)):
                if g == "c":
                    (line,) = ax.plot(
                        data["Time"],
                        data["CPU Percent"],
                        label=label,
                        linestyle=line_type,
                        color=clr,
                        zorder=priority,
                        linewidth=line_width,
                    )
                elif g == "m":
                    (line,) = ax.plot(
                        data["Time"],
                        data["MEM Usage"],
                        label=label,
                        linestyle=line_type,
                        color=clr,
                        zorder=priority,
                        linewidth=line_width,
                    )
                elif g == "r":
                    (line,) = ax.plot(
                        data["Time"],
                        data["IO Reads"] / 1024.0 / 1024.0,
                        label=label,
                        linestyle=line_type,
                        color=clr,
                        zorder=priority,
                        linewidth=line_width,
                    )

            priority -= 1

        graph_ax[-1].set_xlabel("Time (s)", fontsize=font_label, labelpad=30)
        graph_ax[-1].text(
            0.5,
            -0.5,
            f"\\textbf{{({chr(97+run_id)}) {captions[run_id]}}}",
            transform=graph_ax[-1].transAxes,
            ha="center",
            va="top",
            fontsize=font_caption,
        )

        if run_id == 0:
            graph_ax[0].text(
                -0.16,
                0.37,
                "CPU (Percent)",
                transform=graph_ax[0].transAxes,
                ha="center",
                va="center",
                rotation="vertical",
                fontsize=font_label,
            )
            
            graph_ax[1].text(
                -0.16,
                0.37,
                "Memory (GiB)",
                transform=graph_ax[1].transAxes,
                ha="center",
                va="center",
                rotation="vertical",
                fontsize=font_label,
            )

        for ax in graph_ax:
            ax.tick_params(axis="both", labelsize=font_tick, pad=10)
            ax.grid()

    if not no_legend:
        ax = run_graphs[0][0]
        handles, labels = ax.get_legend_handles_labels()
        ax = run_graphs[-1][-1]
        ax.legend(handles=handles, labels=labels, fontsize=font_legend)

    plt.savefig("liveplot.pgf", bbox_inches="tight")
    plt.savefig("liveplot.png", bbox_inches="tight")
    print("Saved: liveplot.pgf")
    print("Saved: liveplot.png")

if __name__ == "__main__":
    plot_run()
