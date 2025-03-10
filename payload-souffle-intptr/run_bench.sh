#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
workers_low=4
workers_high=64

source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"Si"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="souffle "$dl.dl" -F $DATA/$dd/$ds -D . -j $w"
			tag="$dl"_"$ds"_"$w"_souffle-intptr

			set +e
			timeout 600s dlbench run "$cmd" "$tag"
			ret=$?
			set -e

			if [[ $ret == 0 ]]; then
				sed -n "s/$key[[:space:]]*\([0-9]*\)/\1/p" $tag*.out >$tag.info
			elif [[ $ret == 127 || $ret == 137 ]]; then
				echo T/O >$tag.info
			else
				echo DNF >$tag.info
			fi
		done
	fi
done
