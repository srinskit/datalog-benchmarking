#!/bin/bash

# Exit script on error
set -e

DATA=/data/input
workers_low=4
workers_high=64

source targets.sh

for target in "${targets[@]}"; do
	read -r dl dp key charmap threads tout <<<"$target"
	ds=`basename $dp`

	if [ -z "$tout" ]; then
		tout=600s
	fi

	if [[ "$charmap" == *"Si"* ]]; then
		IFS=',' read -ra workers <<<"$threads"
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $ds, workers: $w"
			cmd="souffle "$dl.dl" -F $DATA/$dp -D . -j $w"
			tag="$dl"_"$ds"_"$w"_souffle-intptr
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

			sed -n "s/$key[[:space:]]\([0-9]*\)/DLOut: \1/Ip" $tag*.out >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
