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

ssh -A $HOST "sudo swapoff -a"

echo
echo "[launch] moving payload: local ---> host"
cp targets.sh $PAYLOAD/
$RSYNC --rsync-path="sudo rsync" $PAYLOAD $HOST:$WORK_DIR
rm $PAYLOAD/targets.sh

# Execute benchmark script in host
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; sudo ./run_bench.sh"

# Sync local payload from host payload, except the run_bench.sh file
echo "[launch] moving payload: local <--- host"
$RSYNC --rsync-path="sudo rsync" --include="*.log" --include="*.info" --include="*.out" --exclude="*" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $PAYLOAD 

mv $PAYLOAD/*.log . || true
mv $PAYLOAD/*.info . || true
mv $PAYLOAD/*.out . || true