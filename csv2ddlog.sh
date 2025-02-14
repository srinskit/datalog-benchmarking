#!/bin/bash

# Check if there are at least two arguments and an even number of parameters
if [ $# -lt 4 ] || [ $(($# % 2)) -ne 0 ]; then
	echo "[csv2ddlog] Usage: $0 output_file shuf|noshuf edb1 src1 [edb2 SRC2 ...]"
	echo "[csv2ddlog] Example: ./csv2ddlog.sh andersen.ddin shuf AddressOf addressOf.csv Assign assign.csv Load load.csv Store store.csv"
	exit 1
fi

op_file=$1
shuf_mode=$2
tmp_file=csv2ddlog.tmp

# Validate shuffle mode
if [[ "$shuf_mode" != "shuf" && "$shuf_mode" != "noshuf" ]]; then
	echo "[csv2ddlog] Error: shuffle mode (argument 2) must be 'shuf' or 'noshuf'"
	exit 1
fi

# Move to the next paramter pair
shift 2

# Clear the output file
truncate --size 0 $tmp_file

list_of_csv=""

# Iterate through the parameters two at a time
while [ $# -gt 1 ]; do
	edb=$1
	src=$2
	echo "[csv2ddlog] Processing: $edb, $src"
	sed "s/\(.*\)/insert $edb(\1),/" $src >> $tmp_file
	list_of_csv="$list_of_csv $src"

	# Move to the next paramter pair
	shift 2
done

# Write "start" into the output file
echo "start;" > $op_file

# Shuffle output if requested
if [[ "$shuf_mode" == "shuf" ]]; then
	shuf $tmp_file >> $op_file
else
	cat $tmp_file >> $op_file
fi

rm $tmp_file

# Set the last character in the output file with as semi-colon
sed -i '$ s/.$/;/' $op_file

# Write "commit" into the output file
echo "commit;" >> $op_file

echo
echo "[csv2ddlog] Number of lines in inputs:"
wc -l $list_of_csv

echo
echo "[csv2ddlog] Number of lines in output (incl start and commit):"
wc -l $op_file

echo
echo "[csv2ddlog] Preview of sample:"
head -n 5 $op_file
echo "..."
tail -n 5 $op_file