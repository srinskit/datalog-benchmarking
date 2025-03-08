#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle
exe=$SRC/FlowLogTest/target/release/executing

source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"E"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="$exe --program $dl.dl --facts $DATA/$dd/$ds --csvs output --workers $w"
			tag="$dl"_"$ds"_"$w"_eclair
			dlbench run "$cmd" $tag
			sed -n "s/Delta of.*\[$key\]: ((), (), \([0-9]*\))/\1/p" $tag*.out >$tag.info
		done
	fi
done
