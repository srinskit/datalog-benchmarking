#!/bin/bash

# Exit script on error
set -e

source ../rust_env

PAYLOAD_DIR=$(pwd)
build=1
build_workers=$(nproc)
workers=$(nproc)
dl_program=csda.dl

mkdir -p experiment
cp $dl_program experiment
cp postgresql/* experiment

pushd experiment

dlbench run "souffle $dl_program -F . -D . -j $workers"
