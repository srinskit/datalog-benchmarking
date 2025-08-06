#!/bin/bash

# Exit script on error
set -e

# Set data directory path
DATA=/data/input
# Disable swap to ensure consistent memory performance
swapoff -a

# Load benchmark target programs
source targets.sh

# Iterate through each benchmark target
for target in "${targets[@]}"; do
	# Parse target program parameters: datalog_program, dataset_path, search_key, character_map, thread_counts, timeout
	read -r dl dp key charmap threads tout <<<"$target"
	# Extract dataset name from path
	ds=$(basename $dp)

	# Set default timeout if not specified
	if [ -z "$tout" ]; then
		tout=600s
	fi

	# Check if this target supports Umbra (indicated by 'U' in charmap)
	if [[ "$charmap" == *"U"* ]]; then
		# Parse comma-separated thread counts
		IFS=',' read -ra workers <<<"$threads"
		# Run benchmark for each worker count
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $ds, workers: $w"
			# Create unique tag for this benchmark run
			tag="$dl"_"$ds"_"$w"_umbra
			# Replace slashes with dashes for valid filename
			tag="${tag//\//-}"

			# Build Docker command for Umbra benchmark
			cmd="docker run \
				--rm \
				--cpuset-cpus='0-$w' \
				-v '$DATA/$dp:/data' \
				-v '$(pwd):/payload' \
				-w /payload \
				--user root \
				umbradb/umbra:25.07.1 \
				/usr/local/bin/umbra-sql -createdb '/payload/test.db' '/payload/$dl.sql'"

			# Clear system caches for consistent benchmarking
			sync && sysctl vm.drop_caches=3

			# Temporarily allow command failures to capture exit codes
			set +e
			# Run benchmark with timeout and capture execution time
			/usr/bin/time -f "LinuxRT: %e" timeout $tout dlbench run "$cmd" "$tag" 2>$tag.info
			ret=$?
			# Re-enable exit on error
			set -e

			# Determine benchmark result status based on exit code
			if [[ $ret == 0 ]]; then
				echo "Status: CMP" >>$tag.info  # Completed successfully
			elif [[ $ret == 124 ]]; then
				echo "Status: TOUT" >>$tag.info  # Timeout
			elif [[ $ret == 137 ]]; then
				echo "Status: OOM" >>$tag.info   # Out of memory
			else
				echo "Status: DNF" >>$tag.info   # Did not finish (other error)
			fi

			# Extract and record benchmark metrics
			echo "DLOut: $(grep -A1 -i "$key" $tag*.out | tail -1)" >>$tag.info      # Query result
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info    # Runtime
			echo "load_time: $(grep -A1 -i "load_time" $tag*.out | tail -1)" >>$tag.info  # Data load time
		done
	fi
done
