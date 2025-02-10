#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/eclair
# workers=$(nproc)
workers=4
exe=$SRC/FlowLogTest/target/release/executing

dlbench run "$exe --program sg.dl --facts $DATA/G5K-0.001 --csvs output --workers $workers" "eclair-sg"
