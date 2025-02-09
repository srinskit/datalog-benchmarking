#!/bin/bash

# Exit script on error
set -e

source ../rust_env

PAYLOAD_DIR=$(pwd)
SRC=/usr/local/src
DATA=$SRC/data
build=1
build_workers=$(nproc)
workers=4
exe=souffle_cmpl
dl_program=sg.dl

if [[ $build == 1 ]]; then
	souffle -o $exe $dl_program -j $build_workers -v
fi

dlbench run "./$exe -F $DATA/livejournal -D . -j $workers"
