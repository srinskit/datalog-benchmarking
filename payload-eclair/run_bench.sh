#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle
workers_low=4
workers_high=64
exe=$SRC/FlowLogTest/target/release/executing

dlbench run "$exe --program sg.dl --facts $DATA/G5K-0.001 --csvs output --workers $workers_low" "sg-G5K-$workers_low-eclair"
dlbench run "$exe --program sg.dl --facts $DATA/G5K-0.001 --csvs output --workers $workers_high" "sg-G5K-$workers_high-eclair"

dlbench run "$exe --program andersen.dl --facts $DATA/andersen/500000 --csvs output --workers $workers_low" "andersen-500000-$workers_low-eclair"
dlbench run "$exe --program andersen.dl --facts $DATA/andersen/500000 --csvs output --workers $workers_high" "andersen-500000-$workers_high-eclair"
