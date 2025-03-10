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
			/usr/bin/time -f "LinuxRT: %e" timeout 600s dlbench run "$cmd" "$tag" -m quickstep_cli_shell 2>$tag.info
			ret=$?
			set -e

			# Evaluate result
			if [[ $ret == 0 ]]; then
				echo "Status: CMP" >>$tag.info
			elif [[ $ret == 127 || $ret == 137 ]]; then
				echo "Status: TOUT" >>$tag.info
			else
				echo "Status: DNF" >>$tag.info
			fi

			# sed -n "s/Delta of.*\[$key\]: ((), (), \([0-9]*\))/DLOut: \1/p" $tag*.out >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
