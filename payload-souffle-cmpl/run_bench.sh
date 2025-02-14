#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
build_workers=$(nproc)
workers_low=4
workers_high=64
exe=souffle_cmpl

# souffle -o $exe sg.dl -j $build_workers -v
# dlbench run "./$exe -F $DATA/G5K-0.001 -D . -j $workers_low" "sg-$workers_low-souffle-cmpl"
# dlbench run "./$exe -F $DATA/G5K-0.001 -D . -j $workers_high" "sg-$workers_high-souffle-cmpl"

souffle -o $exe andersen.dl -j $build_workers -v
dlbench run "./$exe -F $DATA/andersen-500000 -D . -j $workers_low" "andersen-500000-$workers_low-souffle-cmpl"
