#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
workers_low=4
workers_high=64

dl=sg
dlbench run "souffle "$dl.dl" -F $DATA/G5K-0.001 -D . -j $workers_low" "$dl-$workers_low-souffle-intptr"
dlbench run "souffle "$dl.dl" -F $DATA/G5K-0.001 -D . -j $workers_high" "$dl-$workers_high-souffle-intptr"

dl=andersen
dlbench run "souffle $dl.dl -F $DATA/andersen/500000 -D . -j $workers_low" "andersen-500000-$workers_low-souffle-intptr"
dlbench run "souffle $dl.dl -F $DATA/andersen/500000 -D . -j $workers_high" "andersen-500000-$workers_high-souffle-intptr"
