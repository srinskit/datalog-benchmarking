#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle
workers_low=4
workers_high=64

source $SRC/recstep_env

# dlbench run "recstep --program sg.dl --input $DATA/G5K-0.001 --jobs $workers_low" "sg-$workers_low-recstep" -m quickstep_cli_shell
# dlbench run "recstep --program sg.dl --input $DATA/G5K-0.001 --jobs $workers_high" "sg-$workers_high-recstep" -m quickstep_cli_shell
dlbench run "recstep --program andersen.dl --input $DATA/andersen-500000 --jobs $workers_low" "andersen-500000-$workers_low-recstep" -m quickstep_cli_shell
