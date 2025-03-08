#!/bin/bash

# Set default values
size=${1:-400}
total_size=${2:-1000}

gen_random_numbers() {
	for ((i = 0; i < size; i++)); do
		echo $((RANDOM % total_size + 1))
	done
}

gen_random_numbers >Source.csv

echo "Random numbers saved to Source.csv"
