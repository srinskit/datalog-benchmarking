#!/bin/bash

# Exit script on error
set -e

DATA=/data/input
build_workers=$(nproc)
exe=souffle_cmpl
cmpl_time=0
prev_dl=""

source targets.sh

for target in "${targets[@]}"; do
	read -r dl dp key charmap threads tout <<<"$target"
	ds=`basename $dp`

	if [ -z "$tout" ]; then
		tout=600s
	fi

	if [[ "$charmap" == *"Sc"* ]]; then
		IFS=',' read -ra workers <<<"$threads"
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $ds, workers: $w"
			tag="$dl"_"$ds"_"$w"_souffle-cmpl
			tag="${tag//\//-}"

			# Build program
			if [ "$prev_dl" != "$dl" ]; then
				start=$(date +%s.%N)
				souffle -o $exe "$dl".dl -j $build_workers &>$tag.compile
				end=$(date +%s.%N)
				cmpl_time=$(echo "$end - $start" | bc)
				prev_dl="$dl"
			fi

			printf "CompileTime: %.2f\n" "$cmpl_time" >$tag.info

			killall $exe || true
			cmd="./$exe -F $DATA/$dp -D . -j $w"

			sync && sysctl vm.drop_caches=3
			set +e
			/usr/bin/time -f "LinuxRT: %e" timeout $tout dlbench run "$cmd" "$tag" 2>>$tag.info
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
