#!/bin/bash

# Example: ./deploy.sh bench.sh srinskit@c220g5.wisc.cloudlab.us ~/keys/srinwisc

WORK_DIR=/opt
SRC=/usr/local/src

PROJECT=${1%/} # Strip trailing slash to create new dest dir with rsync
BENCH_SCRIPT=$2
HOST=$3
SSH_KEY=$4

BENCH_FILE=$(basename $BENCH_SCRIPT)

ssh-add $SSH_KEY

# Copy project and benchmark script to host working dir
rsync -a --rsync-path="sudo rsync" $PROJECT $HOST:$WORK_DIR
rsync --rsync-path="sudo rsync" $BENCH_SCRIPT $HOST:$WORK_DIR

# Execute benchmark script in host
ssh $HOST "cd $WORK_DIR; sudo ./$BENCH_FILE"

# TODO: copy .log files from HOST to local
