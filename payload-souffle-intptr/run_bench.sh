#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
workers_low=4
workers_high=64

source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds <<<"$target"

	for w in "${workers[@]}"; do
		echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
		cmd="souffle "$dl.dl" -F $DATA/$dd/$ds -D . -j $w"
		dlbench run "$cmd" "$dl"_"$ds"_"$w"_souffle-intptr
	done
done
