#!/usr/bin/python

import sys
import os
import csv


def process_dir(dir):
    run_set = set()

    for entry in os.listdir(dir):
        path = os.path.join(dir, entry)
        if os.path.isfile(path):
            run_set.add(os.path.splitext(path)[0])

    for run_path in run_set:
        run_name = os.path.basename(run_path)
        info_file = run_path + ".info"
        out_file = run_path + ".out"
        log_file = run_path + ".log"

        info_map = {"folder": os.path.basename(dir)}
        run_attr = ["program", "dataset", "threads", "engine"]
        run_attr_vals = run_name.split("_")

        if len(run_attr_vals) != len(run_attr):
            print(f"[error]: invalid run name: {run_name}")
            exit(1)

        for key, val in zip(run_attr, run_attr_vals):
            info_map[key] = val

        if os.path.isfile(info_file):
            with open(info_file, "r") as file:
                for line in file:
                    kv_arr = line.split(":")

                    if len(kv_arr) == 2:
                        info_map[kv_arr[0].strip()] = kv_arr[1].strip()

        peak_mem = 0

        if os.path.isfile(log_file):
            with open(log_file, newline="") as file:
                reader = csv.DictReader(file)
                for row in reader:
                    try:
                        peak_mem = max(peak_mem, int(row["MEM Usage"]))
                    except ValueError:
                        print(f"[error]: invalid memory usage value in row: {row}")
                        exit(1)

            info_map["peak_mem"] = str(peak_mem)

        header = [
            "program",
            "dataset",
            "engine",
            "threads",
            "Status",
            "LinuxRT",
            "DLOut",
            "DLBenchRT",
            "CompileTime",
            "folder",
            "peak_mem",
        ]

        csv_row = [info_map.get(col, "") for col in header]
        print(",".join(csv_row))


def main():
    if len(sys.argv) < 2:
        print("Usage: log2csv dir [dir ...]")
        exit(1)
    else:
        dirs = sys.argv[1:]
        # print("[info] processing dirs:", dirs)

        for f in dirs:
            if not os.path.isdir(f):
                print(f"[error] invalid dir {f}")
                exit(1)

        for f in dirs:
            process_dir(f)


main()
