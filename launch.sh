#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us sshkey payload

# Exit script on error
set -e

WORK_DIR=~
SRC=/opt

HOST=$1
PAYLOAD=${2%/} # Strip trailing slash to create new dest dir with rsync

PAYLOAD_DIR=$(basename $PAYLOAD)
RSYNC="rsync -ah --info=progress2 --info=name0 --delete"

# Copy dataset from remote to local
echo "[launch] Setting up local dataset"
/usr/bin/time -f "Local dataset setup took: %E" ssh -A $HOST "sudo cp -an /remote/. /data/"

ssh -A $HOST "sudo swapoff -a; sudo rm -rf /opt/grpc"

echo
echo "[launch] moving payload: local ---> host"
cp $PROJECT_ROOT/targets.sh $PAYLOAD/
$RSYNC --rsync-path="sudo rsync" $PAYLOAD $HOST:$WORK_DIR
rm $PAYLOAD/targets.sh

# Execute benchmark script in host (prefer Python version if available)
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; if [ -f run_bench.py ]; then sudo python3 ./run_bench.py; else sudo ./run_bench.sh; fi"

# Sync local payload from host payload, except the run_bench scripts
echo "[launch] moving payload: local <--- host"
$RSYNC --rsync-path="sudo rsync" --include="*.log" --include="*.profile" --include="*.info" --include="*.out" --include="*.json" --exclude="*" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $PAYLOAD 

ssh -A $HOST "sudo rm -rf $WORK_DIR/$PAYLOAD_DIR"

mv $PAYLOAD/*.{log,profile,info,out,json} . 2>/dev/null || true
