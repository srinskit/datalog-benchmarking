#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us "D,F0,R,Sc,Si"

# Exit script on error
set -e

WORK_DIR=~
SRC=/opt

HOST=$1
ENGINES=$2

PAYLOAD_DIR="cloudlab-auto"
RSYNC="rsync -ah --info=progress2 --info=name0 --delete"

resultdir="dlbench-results"
ts=$(date +"%m-%d-%H-%M-%S")
folder="$resultdir/result$ts"
mkdir -p $folder

# Copy dataset from remote to local
echo "[launch] Setting up local dataset"
/usr/bin/time -f "Local dataset setup took: %E" ssh -A $HOST "sudo cp -an /remote/. /data/"

ssh -A $HOST "sudo swapoff -a; sudo rm -rf /opt/grpc"

echo
echo "[launch] sync: local ---> host"
$RSYNC --rsync-path="sudo rsync" --include="targets.json" --include="run_bench.py" --include="payload-*/" --include="payload-*/**" --exclude="*" . $HOST:$WORK_DIR/$PAYLOAD_DIR

# Execute unified benchmark script with engine parameter
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; sudo bash -c 'source $SRC/rust_env && source $SRC/ddlog_env && source $SRC/recstep_env && python3 ./run_bench.py \"$ENGINES\"'"


# Sync results back from host
echo "[launch] sync: local <--- host"
$RSYNC --rsync-path="sudo rsync" --include="*.log" --include="*.profile" --include="*.err" --include="*.out" --include="*.json" --exclude="*" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $folder

ssh -A $HOST "sudo rm -rf $WORK_DIR/$PAYLOAD_DIR"
