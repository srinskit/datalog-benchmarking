#!/bin/bash

# Exit script on error
set -e

source ../rust_env

PAYLOAD_DIR=$(pwd)
build=1
build_workers=$(nproc)
workers=$(nproc)
exe=souffle_csda
dl_program=csda.dl

if [[ $build == 1 ]]; then
	souffle -o $exe $dl_program -j $build_workers -v
fi

mkdir -p experiment
cp $dl_program experiment
cp postgresql/* experiment
cp $exe experiment

pushd experiment

dlbench run "./$exe -F . -D . -j $workers"
