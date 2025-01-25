#!/bin/bash

# Exit script on error
set -e

source ../rust_env

PAYLOAD_DIR=$(pwd)
build=1
project=FlowLogTest
build_workers=$(nproc)
workers=$(nproc)
exe=executing
dl_program=csda.dl

killall cargo || true

if [[ $build == 1 ]]; then

	# Update or clone the project

	export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

	if [[ -d $project ]]; then
		chown -R $USER $project
		pushd $project
		git pull origin main
	else
		git clone git@github.com:hdz284/$project.git
		pushd $project
	fi

	echo "Build workers: " $build_workers
	cargo fetch

	# Patch DD

	patch_dst=$(find $CARGO_HOME -path "*/differential-dataflow-0.13.2/src/collection.rs")
	patch_src=$PAYLOAD_DIR/collection.rs

	if cmp -s $patch_src $patch_dst; then
		echo "[run_bench] DD already patched"
	else
		echo "[run_bench] Patching DD"

		chmod a+w $patch_dst
		cp $patch_src $patch_dst
		cargo clean -p differential-dataflow --release
		cargo build -p differential-dataflow --release
	fi

	# Build the project
	cargo build --release -j $build_workers
	popd

	# Extract the binaries and data
	mkdir -p experiment
	cp $project/examples/programs/$dl_program experiment
	cp -r $project/examples/facts experiment
	cp $project/target/release/$exe experiment
fi

pushd experiment

dlbench run "./$exe --program $dl_program --facts facts --csvs output --workers $workers"