#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
build_workers=$(nproc)
exe=souffle_cmpl
prev_dl=""

source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"Sc"* ]]; then
		# Build program
		if [ "$prev_dl" != "$dl" ]; then
			souffle -o $exe "$dl".dl -j $build_workers
			prev_dl="$dl"
		fi

		for w in "${workers[@]}"; do
			killall $exe || true
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="./$exe -F $DATA/$dd/$ds -D . -j $w"
			tag="$dl"_"$ds"_"$w"_souffle-cmpl
			dlbench run "$cmd" "$tag"
			sed -n "s/$key[[:space:]]*\([0-9]*\)/\1/p" $tag*.out >$tag.info
		done
	fi
done
