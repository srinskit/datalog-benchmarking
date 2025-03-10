#!/bin/bash

workers=(4 64)
engines=("eclair" "souffle-cmpl" "souffle-intptr" "recstep" "ddlog")
delim="_"

parse_info() {
	local rfile="$1"
	local keyword="$2"
	sed -n "s/$keyword: \(.*\)/\1/p" $rfile
}

print_runtimes() {
	local rdir="$1"
	local prefix="$2"
	local stat_line=""
	local corr_line=""
	local status_line=""
	local delta_line=""
	local dl_program dataset
	local csv_delim=$'\t'

	IFS=$delim read -r dl_program dataset _ <<<"$prefix"

	if [[ -n "$dl_program" && -n "$dataset" ]]; then
		x=1
	else
		echo "Error: Could not extract Datalog program and dataset from log file name."
		exit 1
	fi

	for e in "${engines[@]}"; do
		for n in "${workers[@]}"; do
			local rfile_pattern="$prefix$delim${n}$delim${e}"
			local rfiles=($(find $rdir -type f -name "*$rfile_pattern*.info"))
			local nfiles=${#rfiles[@]}

			# Check the number of matching files
			if [[ $nfiles == 1 ]]; then
				stat_line="$stat_line"$(parse_info "${rfiles[0]}" "LinuxRT")"$csv_delim"
				corr_line="$corr_line"$(parse_info "${rfiles[0]}" "DLOut")"$csv_delim"
				status_line="$status_line"$(parse_info "${rfiles[0]}" "Status")"$csv_delim"
				delta_line="$delta_line"$(parse_info "${rfiles[0]}" "DLBenchRT")"$csv_delim"
			elif [[ $nfiles == 0 ]]; then
				stat_line="$stat_line""N/A""$csv_delim"
				corr_line="$corr_line""N/A""$csv_delim"
				status_line="$status_line""N/A""$csv_delim"
				delta_line="$delta_line""N/A""$csv_delim"
			else
				echo "Error: Found ${#rfiles[@]} file matching the pattern $rfile_pattern. Expected exactly one."
				exit 1
			fi
		done
	done

	base_rdir=$(basename $rdir)
	echo -e "$dl_program\t$dataset\t""$stat_line""$corr_line""$status_line""$delta_line""$base_rdir"
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
