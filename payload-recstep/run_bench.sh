#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle

source $SRC/recstep_env
source bench_targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"R"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="recstep --program $dl.dl --input $DATA/$dd/$ds --jobs $w"
			tag="$dl"_"$ds"_"$w"_recstep

			set +e
			timeout 600s dlbench run "$cmd" "$tag" -m quickstep_cli_shell
			ret=$?
			set -e

			if [[ $ret == 0 ]]; then
				echo CMP >$tag.info
			elif [[ $ret == 127 || $ret == 137 ]]; then
				echo T/O >$tag.info
			else
				echo DNF >$tag.info
			fi
		done
	fi
done
