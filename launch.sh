#!/bin/bash

# Example: ./launch.sh user@mach.cloudlab.us sshkey payload

WORK_DIR=/opt
SRC=/usr/local/src

HOST=$1
SSH_KEY=$2
BENCH_SCRIPT=$3
PAYLOAD=${4%/} # Strip trailing slash to create new dest dir with rsync

BENCH_FILE=$(basename $BENCH_SCRIPT)

ssh-add $SSH_KEY

# Copy benchmark and PAYLOAD script to host working dir
rsync --rsync-path="sudo rsync" $BENCH_SCRIPT $HOST:$WORK_DIR

if [ -n "$PAYLOAD" ]; then
	rsync -a --rsync-path="sudo rsync" $PAYLOAD $HOST:$WORK_DIR
fi

# Execute benchmark script in host
ssh -A $HOST "cd $WORK_DIR; sudo ./$BENCH_FILE"

# TODO: copy .log files from HOST to local
