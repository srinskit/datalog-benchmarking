#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us sshkey payload

# Exit script on error
set -e

WORK_DIR=~
SRC=/opt

HOST=$1
PAYLOAD=${2%/} # Strip trailing slash to create new dest dir with rsync

PAYLOAD_DIR=$(basename $PAYLOAD)

RSYNC="rsync -a --info=progress2 --info=name0"

echo "[Launch] syncing host with src payload"
$RSYNC --rsync-path="sudo rsync" $PAYLOAD $HOST:$WORK_DIR

# Execute benchmark script in host
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; sudo ./run_bench.sh"

# Sync local payload from host payload, except the run_bench.sh file
echo "[Launch] syncing src with host payload"
# $RSYNC --rsync-path="sudo rsync" --exclude "run_bench.sh" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $PAYLOAD 
$RSYNC --rsync-path="sudo rsync" --include="*.log" --exclude="*" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $PAYLOAD 
mv $PAYLOAD/*.log . || true