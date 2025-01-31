#!/bin/bash

# Exit script on error
set -e

source ../recstep_env

PAYLOAD_DIR=$(pwd)
workers=$(nproc)
dl_program=csda.dl

mkdir -p experiment
pushd experiment

# recstep --program $PAYLOAD_DIR/tc.datalog --input $PAYLOAD_DIR/Input --jobs $workers
dlbench run "recstep --program $PAYLOAD_DIR/$dl_program --input $PAYLOAD_DIR/postgresql --jobs $workers"
