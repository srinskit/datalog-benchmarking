#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input
exe=$SRC/FlowLogTest/target/release/executing

swapoff -a

source targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap threads tout <<<"$target"

	if [ -z "$tout" ]; then
		tout=600s
	fi

	if [[ "$charmap" == *"F0"* ]]; then
		IFS=',' read -ra workers <<<"$threads"
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="$exe --program $dl.dl --facts $DATA/$dd/$ds --csvs . --workers $w"
			tag="$dl"_"$ds"_"$w"_flowlog
			tag="${tag//\//-}"

			sync && sysctl vm.drop_caches=3

			set +e
			/usr/bin/time -f "LinuxRT: %e" timeout $tout dlbench run "$cmd" "$tag" 2>$tag.info
			ret=$?
			set -e

			# Evaluate result
			if [[ $ret == 0 ]]; then
				echo "Status: CMP" >>$tag.info
			elif [[ $ret == 124 ]]; then
				echo "Status: TOUT" >>$tag.info
			elif [[ $ret == 137 ]]; then
				echo "Status: OOM" >>$tag.info
			else
				echo "Status: DNF" >>$tag.info
			fi

			sed -n "s/Delta of.*\[$key\]: ((), (), \([0-9]*\))/DLOut: \1/Ip" $tag*.out >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
