#!/bin/bash

# Exit script on error
set -e

PAYLOAD_DIR=$(pwd)
SRC=/opt
DATA=/data/input/eclair
workers=$(nproc)
exe=$SRC/FlowLogTest/target/release/executing

dlbench run "$exe --program $PAYLOAD_DIR/sg.dl --facts $DATA/G5K-0.001 --csvs output --workers $workers" "eclair-sg"
