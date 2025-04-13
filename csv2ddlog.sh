#!/bin/bash

# Exit script on error
set -e

# Check if there are at least two arguments and an even number of parameters
if [ $# -lt 3 ] || [ $(($# % 2)) -ne 1 ]; then
	echo "[csv2ddlog] Usage: $0 output_file shuf|noshuf auto|manual [edb1 src1 edb2 SRC2 ...]"
	echo "[csv2ddlog] Example: ./csv2ddlog.sh andersen.ddin shuf auto"
	echo "[csv2ddlog] Example: ./csv2ddlog.sh andersen.ddin shuf manual AddressOf addressOf.csv Assign assign.csv Load load.csv Store store.csv"
	exit 1
fi

op_file=$1
shuf_mode=$2
detect_mode=$3
tmp_file=csv2ddlog.tmp

# Validate shuffle mode
if [[ "$shuf_mode" != "shuf" && "$shuf_mode" != "noshuf" ]]; then
	echo "[csv2ddlog] Error: shuffle mode (argument 2) must be 'shuf' or 'noshuf'"
	exit 1
fi

# Validate detect mode
if [[ "$detect_mode" != "auto" && "$detect_mode" != "manual" ]]; then
	echo "[csv2ddlog] Error: detect mode (argument 3) must be 'auto' or 'manual'"
	exit 1
fi

# Clear the output file
truncate --size 0 $tmp_file

list_of_csv=""

if [[ "$detect_mode" == "auto" ]]; then
	# Iterate through all .csv and .facts files in the current directory
	for src in *.csv *.facts; do
		# Check if the file actually exists (in case there are no matching files)
		if [ -f "$src" ]; then
			# Extract the filename without the extension
			edb="${src%.*}"
			# Capitalize the first character
			edb="${edb^}"
			echo "[csv2ddlog] Processing: $edb, $src"
			sed "s/\(.*\)/insert $edb(\1),/" $src >>$tmp_file
			list_of_csv="$list_of_csv $src"
		fi
	done
else
	# Move to the next paramter pair
	shift 3

	# Iterate through the parameters two at a time
	while [ $# -gt 1 ]; do
		edb=$1
		src=$2
		echo "[csv2ddlog] Processing: $edb, $src"
		sed "s/\(.*\)/insert $edb(\1),/" $src >>$tmp_file
		list_of_csv="$list_of_csv $src"

		# Move to the next paramter pair
		shift 2
	done
fi

# Write "start" into the output file
echo "start;" >$op_file

# Shuffle output if requested
if [[ "$shuf_mode" == "shuf" ]]; then
	shuf $tmp_file >>$op_file
else
	cat $tmp_file >>$op_file
fi

rm $tmp_file

# Set the last character in the output file with as semi-colon
sed -i '$ s/.$/;/' $op_file

# Write "commit" into the output file
echo "commit;" >>$op_file
echo "dump RelationSizes;" >>$op_file

echo
echo "[csv2ddlog] Number of lines in inputs:"
wc -l $list_of_csv

echo
echo "[csv2ddlog] Number of lines in output (incl Source and commit):"
wc -l $op_file

echo
echo "[csv2ddlog] Preview of sample:"
head -n 5 $op_file
echo "..."
tail -n 5 $op_file
