#!/bin/bash

# Exit script on error
set -e

source rust_env

WORK_DIR=$(pwd)
build=1
project=FlowLogTest
build_workers=$(nproc)
workers=$(nproc)
exe=executing

killall cargo || true

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

	echo "Build workers: " $build_workers

	# Patch DD
	patch_path=$(find $CARGO_HOME -path "*/differential-dataflow-0.13.2/src/collection.rs")
	chmod a+w $patch_path
	echo $patch_path
	cp $WORK_DIR/hd/collection.rs $patch_path
	cargo clean -p differential-dataflow --release
	cargo build -p differential-dataflow --release

	# Build the project
	cargo build --release -j $build_workers
	popd

	# Extract the binaries and data
	mkdir -p experiment
	cp $project/examples/programs/java.dl experiment
	cp -r $project/examples/facts experiment
	cp $project/target/release/$exe experiment
fi

pushd experiment

./$exe --program java.dl --facts facts --csvs output --workers 4