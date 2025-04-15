#!/bin/bash

# Exit script on error
set -e

source rust_env

WORK_DIR=$(pwd)
node=$(hostname -s)
main_node="node0"
other_nodes=("node1" "node2")
num_nodes=3
participant_num="${node:4}"
build=1
project=FlowLogTest
notif="notif"
start_time=$(date +%s)
workers=$(nproc)
exe=executing

echo "$node"

if [[ "$node" == "$main_node" ]];
then
	if [[ $build == 1 ]];
	then
		# If obtaining src from local machine
		# unzip $project-main.zip
		# mv $project-main $project

		export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

		# Update or clone the project
		if [[ -d $project ]];
		then
			pushd $project
			git pull origin main
		else
			git clone git@github.com:hdz284/$project.git
			pushd $project
		fi

		# Build the project
		killall cargo || true
		cargo build --release -j $workers
		popd

		# Extract the binaries and data
		mkdir -p experiment
		cp $project/examples/programs/java.dl experiment
		cp -r $project/examples/facts experiment
		cp $project/target/release/$exe experiment
		touch $notif

		for remote in "${other_nodes[@]}"
		do
			rsync --rsh="ssh -o StrictHostKeyChecking=no" -a --rsync-path="sudo rsync" experiment $remote:$WORK_DIR
			rsync --rsh="ssh -o StrictHostKeyChecking=no" --rsync-path="sudo rsync" $notif $remote:$WORK_DIR
		done
	fi
else
	echo Waiting for $main_node to send program

	# Wait until experiment copy notification is received
	until [[ -f "$notif" && $(stat -c %Y "$notif" 2>/dev/null) -ge $start_time ]];
	do
		sleep 1
	done

	echo Received program from $main_node
fi

# All nodes have the dir experiment now
pushd experiment
./$exe --help

./$exe --program java.dl --facts facts --csvs output --workers $workers -n $num_nodes -p $participant_num