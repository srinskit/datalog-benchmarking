#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle
# workers=$(nproc)
workers=4
dl_program=sg.dl

source $SRC/recstep_env

# recstep --program $PAYLOAD_DIR/tc.datalog --input $PAYLOAD_DIR/Input --jobs $workers
dlbench run "recstep --program $dl_program --input $DATA/G5K-0.001 --jobs $workers"
