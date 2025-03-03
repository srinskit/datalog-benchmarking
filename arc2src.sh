#!/bin/bash

# Exit script on error
set -e

if [ $# -ne 2 ]; then
	echo "Usage: $0 <file> <output_file>"
	exit 1
fi

# File path provided as argument
file=$1
out=$2

# Check if the file is provided as an argument
if [ ! -f $file ]; then
	echo "Usage: $0 <file> <output_file>"
	exit 1
fi

# Clear the contents of the output file
>"$out"

# Declare variables for minimum and maximum
min=0
max=

# Read the file line by line
while IFS=',' read -r num1 num2 || [ -n "$num1" ]; do
	if [ -z "$min" ]; then
		min=$num1
		max=$num1
	fi

	min=$((num1 < min ? num1 : min))
	max=$((num1 > max ? num1 : max))
	min=$((num2 < min ? num2 : min))
	max=$((num2 > max ? num2 : max))
done <"$file"

echo "Min: $min, Max: $max"

# Loop to print 10 of the nodes
total_size=$((max - min))
size=10

for ((i = 0; i < size; i++)); do
	echo $((RANDOM % total_size + min)) >>"$out"
done
