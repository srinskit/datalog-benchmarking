#!/bin/bash

# Example: ./deploy-dist.sh hd-dist-bench.sh hosts.txt

WORK_DIR=/opt
SRC=/usr/local/src

BENCH_SCRIPT=$1
HOSTS=$2

readarray -t nodes < $HOSTS 

BENCH_FILE=$(basename $BENCH_SCRIPT)

ssh-add ~/keys/gitssh
ssh-add ~/keys/srinwisc

# Execute benchmark script in every host
for remote in "${nodes[@]}"
do
	echo Host: $remote
	rsync -I --rsync-path="sudo rsync" $BENCH_SCRIPT $remote:$WORK_DIR

	# SSH with agent forwarding to pass on SSH creds
	ssh -A $remote "cd $WORK_DIR; sudo ./$BENCH_FILE" &> $remote.log &
done
