#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us sshkey payload

# Exit script on error
set -e

WORK_DIR=/opt
SRC=/usr/local/src

HOST=$1
PAYLOAD=${2%/} # Strip trailing slash to create new dest dir with rsync

PAYLOAD_DIR=$(basename $PAYLOAD)

echo "[Launch] syncing host with src payload"
rsync -a --rsync-path="sudo rsync" $PAYLOAD $HOST:$WORK_DIR

# Execute benchmark script in host
ssh -A $HOST "cd $WORK_DIR/$PAYLOAD_DIR; sudo ./run_bench.sh"

# Sync local payload from host payload, except the run_bench.sh file
echo "[Launch] syncing src with host payload"
rsync -a --rsync-path="sudo rsync" --exclude "run_bench.sh" $HOST:$WORK_DIR/$PAYLOAD_DIR/ $PAYLOAD 
mv $PAYLOAD/experiment/*.log . || true