#!/bin/bash

# Exit script on error
set -e

DATA=/data/input
swapoff -a

source targets.sh

for target in "${targets[@]}"; do
	read -r dl dp key charmap threads tout <<<"$target"
	ds=$(basename $dp)

	if [ -z "$tout" ]; then
		tout=600s
	fi

	if [[ "$charmap" == *"U"* ]]; then
		IFS=',' read -ra workers <<<"$threads"
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $ds, workers: $w"
			tag="$dl"_"$ds"_"$w"_umbra
			tag="${tag//\//-}"

			cmd="docker run \
				--rm \
				--cpuset-cpus='0-$w' \
				-v '$DATA/$dp:/data' \
				-v '$(pwd):/payload' \
				-w /payload \
				--user root \
				umbradb/umbra:25.07.1 \
				/usr/local/bin/umbra-sql -createdb '/payload/test.db' '/payload/$dl.sql'"

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

			echo "DLOut: $(grep -A1 -i "$key" $tag*.out | tail -1)" >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
