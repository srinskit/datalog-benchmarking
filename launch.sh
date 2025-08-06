#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us "DF0RScSi"

# Exit script on error
set -e

WORK_DIR=~
SRC=/opt

HOST=$1
ENGINES=$2

PAYLOAD_DIR="cloudlab-auto"
RSYNC="rsync -ah --info=progress2 --info=name0 --delete"

# Copy dataset from remote to local
echo "[launch] Setting up local dataset"
/usr/bin/time -f "Local dataset setup took: %E" ssh -A $HOST "sudo cp -an /remote/. /data/"

ssh -A $HOST "sudo swapoff -a; sudo rm -rf /opt/grpc"

echo
echo "[launch] moving payload: local ---> host"
$RSYNC --rsync-path="sudo rsync" --include="targets.*" --include="run_bench.*" --include="payload-*/" --include="payload-*/**" --exclude="*" . $HOST:$WORK_DIR/$PAYLOAD_DIR

# Execute unified benchmark script with engine parameter
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; sudo python3 ./run_bench.py '$ENGINES'"

# Sync results back from host
echo "[launch] moving results: local <--- host"
$RSYNC --rsync-path="sudo rsync" --include="*.log" --include="*.profile" --include="*.err" --include="*.out" --include="*.json" --exclude="*" $HOST:$WORK_DIR/$PAYLOAD_DIR/ .

# ssh -A $HOST "sudo rm -rf $WORK_DIR/$PAYLOAD_DIR"
