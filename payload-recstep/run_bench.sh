#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle

source $SRC/recstep_env
source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds <<<"$target"

	for w in "${workers[@]}"; do
		echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
		cmd="recstep --program $dl.dl --input $DATA/$dd/$ds --jobs $w"
		dlbench run "$cmd" "$dl"_"$ds"_"$w"_recstep -m quickstep_cli_shell
	done
done
