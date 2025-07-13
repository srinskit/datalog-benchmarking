#!/bin/bash

# Exit script on error
set -e

DB=test.db
DATA=/data/input
swapoff -a

source targets.sh

export PATH='/opt/duckdb/cli/latest':$PATH

for target in "${targets[@]}"; do
	read -r dl dp key charmap threads tout <<<"$target"
	ds=$(basename $dp)

	if [ -z "$tout" ]; then
		tout=600s
	fi

	if [[ "$charmap" == *"Q"* ]]; then
		IFS=',' read -ra workers <<<"$threads"
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $ds, workers: $w"
			tag="$dl"_"$ds"_"$w"_duckdb
			tag="${tag//\//-}"
			cmd="duckdb $DB < $dl.sql"

			ln -sf $DATA/$dp /dataset
			rm -f "$DB" 2>/dev/null || true
			sync && sysctl vm.drop_caches=3
			duckdb $DB < "duckdb_config.sql"

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

			echo "DLOut: $(grep -A3 "$key" $tag*.out | tail -1 | grep -o '[0-9]\+')" >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi
done
