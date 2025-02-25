#!/bin/bash

workers=(4 64)
engines=("eclair" "souffle-cmpl" "souffle-intptr" "recstep" "ddlog")
delim="_"

get_runtime() {
	local rfile="$1"
	tail -n 1 $rfile | cut -d ',' -f 1
}

print_runtimes() {
	local rdir="$1"
	local prefix="$2"
	local stat_line=""
	local dl_program dataset

	IFS=$delim read -r dl_program dataset _ <<<"$prefix"

	if [[ -n "$dl_program" && -n "$dataset" ]]; then
		stat_line="$dl_program\t$dataset"
	else
		echo "Error: Could not extract Datalog program and dataset from log file name."
		exit 1
	fi

	for e in "${engines[@]}"; do
		for n in "${workers[@]}"; do
			local rfile_pattern="$prefix$delim${n}$delim${e}"
			local rfiles=($(find $rdir -type f -name "*$rfile_pattern*.log"))
			local nfiles=${#rfiles[@]}

			# Check the number of matching files
			if [[ $nfiles == 1 ]]; then
				stat_line="$stat_line\t"$(get_runtime "${rfiles[0]}")
			elif [[ $nfiles == 0 ]]; then
				stat_line="$stat_line\tN/A"
			else
				echo "Error: Found ${#rfiles[@]} file matching the pattern $rfile_pattern. Expected exactly one."
				exit 1
			fi
		done
	done

	echo -e "$stat_line\t$rdir"
}

# Iterate over all arguments (directories/patterns)
for dir in "$@"; do
	# Use 'glob' to expand patterns and handle them properly
	for rdir in $dir; do
		# Check if it's a valid directory
		if [[ -d "$rdir" ]]; then
			for batch_prefix in $(find $rdir -type f -name "*.log" -printf "%f\n" | cut -d $delim -f 1,2 | sort | uniq); do
				print_runtimes $rdir $batch_prefix
			done
		else
			echo "Warning: $expanded_dir is not a valid directory."
		fi
	done
done
