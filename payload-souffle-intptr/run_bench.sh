#!/bin/bash

# Exit script on error
set -e

DATA=/data/input/souffle
workers=4
dl_program=sg.dl

dlbench run "souffle $dl_program -F $DATA/G5K-0.001 -D . -j $workers" "souffle-intptr-sg"
