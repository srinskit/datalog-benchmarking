#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
workers_low=4
workers_high=64

# dl_program=sg
# dlbench run "souffle "$dl_program.dl" -F $DATA/G5K-0.001 -D . -j $workers_low" "$dl_program-$workers_low-souffle-intptr"
# dlbench run "souffle "$dl_program.dl" -F $DATA/G5K-0.001 -D . -j $workers_high" "$dl_program-$workers_high-souffle-intptr"

dl_program=andersen
dlbench run "souffle $dl_program.dl -F $DATA/andersen-500000 -D . -j $workers_low" "andersen-500000-$workers_low-souffle-intptr"
