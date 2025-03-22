#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
build_workers=$(nproc)
exe=souffle_cmpl
prev_dl=""

source targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"Sc"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			tag="$dl"_"$ds"_"$w"_souffle-cmpl

			# Build program
			if [ "$prev_dl" != "$dl" ]; then
				souffle -o $exe "$dl".dl -j $build_workers &>$tag.compile
				prev_dl="$dl"
			fi

			killall $exe || true
			cmd="./$exe -F $DATA/$dd/$ds -D . -j $w"

			sync && sysctl vm.drop_caches=3
			set +e
			/usr/bin/time -f "LinuxRT: %e" timeout 600s dlbench run "$cmd" "$tag" 2>$tag.info
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

			sed -n "s/$key[[:space:]]\([0-9]*\)/DLOut: \1/Ip" $tag*.out >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
