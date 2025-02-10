#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
build_workers=$(nproc)
# workers=$(nproc)
workers=4
exe=souffle_cmpl
dl_program=sg.dl

souffle -o $exe $dl_program -j $build_workers -v
dlbench run "./$exe -F $DATA/G5K-0.001 -D . -j $workers" "souffle-cmpl-sg"
