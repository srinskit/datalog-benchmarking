#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle
exe=$SRC/FlowLogTest/target/release/executing

source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds <<<"$target"

	for w in "${workers[@]}"; do
		echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
		cmd="$exe --program $dl.dl --facts $DATA/$dd/$ds --csvs output --workers $w"
		dlbench run "$cmd" "$dl"_"$ds"_"$w"_eclair
	done
done
