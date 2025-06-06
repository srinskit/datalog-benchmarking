#!/bin/bash

# Setup a base CloudLab Ubuntu 20.04 image for our experiments

# Exit script on error
set -e

WORK_DIR=/opt

cd $WORK_DIR

# Install PIP

if command -v pip3 >/dev/null 2>&1; then
	echo "[img-setup] pip exists, skipping install."
else
	apt -qq update
	apt -qq install python3-pip -y
fi

# Install DL Bench

if command -v dlbench >/dev/null 2>&1; then
	echo "[img-setup] dlbench exists, skipping install."
else
	rm -rf $WORK_DIR/dlbench
	git clone --depth=1 https://github.com/srinskit/dlbench $WORK_DIR/dlbench
	pip install $WORK_DIR/dlbench/
fi

dlbench --help

# Install Rust

source $WORK_DIR/rust_env || true

if command -v cargo >/dev/null 2>&1; then
	echo "[img-setup] rust exists, skipping install."
else
	export CARGO_HOME=$WORK_DIR/rust
	export RUSTUP_HOME=$WORK_DIR/rust
	RUST_OPS="-q -y --profile minimal"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- $RUST_OPS

	# Save rust env for load during login
	echo "export CARGO_HOME=$WORK_DIR/rust" >$WORK_DIR/rust_env
	echo "export RUSTUP_HOME=$WORK_DIR/rust" >>$WORK_DIR/rust_env
	echo "export PATH=$CARGO_HOME/bin:\$PATH" >>$WORK_DIR/rust_env
	source $WORK_DIR/rust_env

	# For DDLog
	rustup toolchain install 1.76

	cargo install cargo-cache
fi

rustc --version
cargo --version

rustup update

rustc --version
cargo --version

# Install Souffle

if command -v souffle >/dev/null 2>&1; then
	echo "[img-setup] souffle exists, skipping install."
else
	echo "[img-setup] installing Souffle"

	wget https://souffle-lang.github.io/ppa/souffle-key.public -O /usr/share/keyrings/souffle-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/souffle-archive-keyring.gpg] https://souffle-lang.github.io/ppa/ubuntu/ stable main" | tee /etc/apt/sources.list.d/souffle.list
	apt -qq update
	apt -qq install souffle -y
fi

souffle --version

# Install DDLog

source $WORK_DIR/ddlog_env || true

if command -v ddlog >/dev/null 2>&1; then
	echo "[img-setup] ddlog exists, skipping install."
else
	echo "[img-setup] installing ddlog"
	pushd $HOME
	wget -q https://github.com/vmware/differential-datalog/releases/download/v1.2.3/ddlog-v1.2.3-20211213235218-Linux.tar.gz
	tar -xf ddlog-v1.2.3-20211213235218-Linux.tar.gz -C $WORK_DIR

	echo "export DDLOG_HOME=$WORK_DIR/ddlog" >$WORK_DIR/ddlog_env
	echo "export PATH=$PATH:$WORK_DIR/ddlog/bin" >>$WORK_DIR/ddlog_env
	source $WORK_DIR/ddlog_env
fi

ddlog --version

# Install RecStep

## Install QuickStep by copying build from Ubuntu 18 LTS manually as a folder $WORK_DIR/quickstep

## Install RecStep

if [[ ! -d $WORK_DIR/RecStep ]]; then

	## Install GRPC

	if [[ ! -d $WORK_DIR/grpc ]]; then
		apt -qq update -y
		apt -qq install -y clang
		apt -qq install -y clang++ || true
		apt -qq install -y cmake

		export CC=/usr/bin/clang
		export CXX=/usr/bin/clang++

		git clone --depth=1 -b v1.28.1 https://github.com/grpc/grpc $WORK_DIR/grpc

		cd $WORK_DIR/grpc
		git submodule update --init

		make --silent -j $build_workers
		make --silent install

		cd third_party/protobuf
		make --silent install
	fi

	apt -qq update -y
	apt -qq install -y python3-pip python-dev build-essential libjpeg-dev zlib1g-dev
	pip3 install --upgrade pip
	pip3 install cython
	pip3 install matplotlib
	pip3 install psutil
	pip3 install antlr4-python3-runtime==4.8
	pip3 install networkx

	git clone --depth=1 https://github.com/Hacker0912/RecStep $WORK_DIR/RecStep

	pushd $WORK_DIR/RecStep

	# Point config to quickstep
	sed -i "s|/fastdisk/quickstep-datalog/build|/data/quickstep|" $WORK_DIR/RecStep/Config.json

	# Install CLI and env
	echo "#! $(which python3)" > recstep
	cat interpreter.py >> recstep
	chmod +x recstep
	echo "export CONFIG_FILE_DIR=$WORK_DIR/RecStep" > $WORK_DIR/recstep_env
	echo "export PATH=$PATH:$WORK_DIR/RecStep" >> $WORK_DIR/recstep_env
	source $WORK_DIR/recstep_env

	popd
fi

source $WORK_DIR/recstep_env
recstep --help

project=FlowLogTest
target=FlowLogTest
branch=benchmark
flowlog_exe=$WORK_DIR/$target/target/release/executing
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
build_workers=$(nproc)
source $WORK_DIR/rust_env

if [[ 1 == 0 ]]; then
	killall cargo || true

	# Update or clone the project
	rm -rf $target
	git clone --branch $branch --single-branch --depth 1 git@github.com:hdz284/$project.git $target
	pushd $target

	# Patch DD
	cargo cache -a
	cargo fetch
	cargo update differential-dataflow

	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/collection.rs
	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/iterate.rs
	patch_dst=$(find $CARGO_HOME -regex ".*/differential-dataflow-[.0-9]*/src")

	# Test DD crate exists
	[ -d $patch_dst ]

	echo "[run_bench] Patching DD"
	chmod a+w $patch_dst/collection.rs
	chmod a+w $patch_dst/operators/iterate.rs
	cp collection.rs $patch_dst/collection.rs
	cp iterate.rs $patch_dst/operators/iterate.rs
	cargo clean -p differential-dataflow --release
	cargo build -p differential-dataflow --release

	rm collection.rs*
	rm iterate.rs*

	# Build the project
	cargo build --release -j $build_workers
	popd

	$flowlog_exe --help
fi

target=/remote/FlowLogTest1
branch=benchmark1
flowlog_exe=$target/target/release/executing

if [[ 1 == 0 ]]; then
	source $WORK_DIR/rust_env
	killall cargo || true

	# Update or clone the project
	rm -rf $target
	git clone --branch $branch --single-branch --depth 1 git@github.com:hdz284/$project.git $target
	pushd $target

	# Patch DD
	cargo cache -a
	cargo fetch
	cargo update differential-dataflow

	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/collection.rs
	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/iterate.rs
	patch_dst=$(find $CARGO_HOME -regex ".*/differential-dataflow-[.0-9]*/src")

	# Test DD crate exists
	[ -d $patch_dst ]

	echo "[run_bench] Patching DD"
	chmod a+w $patch_dst/collection.rs
	chmod a+w $patch_dst/operators/iterate.rs
	cp collection.rs $patch_dst/collection.rs
	cp iterate.rs $patch_dst/operators/iterate.rs
	cargo clean -p differential-dataflow --release
	cargo build -p differential-dataflow --release

	rm collection.rs*
	rm iterate.rs*

	# Build the project
	cargo build --release -j $build_workers
	popd

	$flowlog_exe --help
fi

target=/remote/FlowLogTest2
branch=aggregation-benchmark
flowlog_exe=$target/target/release/executing

if [[ 1 == 0 ]]; then
	killall cargo || true

	# Update or clone the project
	rm -rf $target
	git clone --branch $branch --single-branch --depth 1 git@github.com:hdz284/$project.git $target
	pushd $target
	rm Cargo.lock

	# Patch DD
	cargo cache -a
	cargo fetch
	cargo update differential-dataflow

	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/collection.rs
	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/iterate.rs
	patch_dst=$(find $CARGO_HOME -regex ".*/differential-dataflow-[.0-9]*/src")

	# Test DD crate exists
	[ -d $patch_dst ]

	echo "[run_bench] Patching DD"
	chmod a+w $patch_dst/collection.rs
	chmod a+w $patch_dst/operators/iterate.rs
	cp collection.rs $patch_dst/collection.rs
	cp iterate.rs $patch_dst/operators/iterate.rs
	cargo clean -p differential-dataflow --release
	cargo build -p differential-dataflow --release

	rm collection.rs*
	rm iterate.rs*

	# Build the project
	cargo build --release -j $build_workers
	popd

	$flowlog_exe --help
fi

target=/remote/FlowLogTest3
branch=sip-tests
flowlog_exe=$target/target/release/executing

if [[ 1 ]]; then
	killall cargo || true

	# Update or clone the project
	rm -rf $target
	git clone --branch $branch --single-branch --depth 1 git@github.com:hdz284/$project.git $target
	pushd $target

	# Patch DD
	cargo cache -a
	cargo fetch
	cargo update differential-dataflow

	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/collection.rs
	wget https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/iterate.rs
	patch_dst=$(find $CARGO_HOME -regex ".*/differential-dataflow-[.0-9]*/src")

	# Test DD crate exists
	[ -d $patch_dst ]

	echo "[run_bench] Patching DD"
	chmod a+w $patch_dst/collection.rs
	chmod a+w $patch_dst/operators/iterate.rs
	cp collection.rs $patch_dst/collection.rs
	cp iterate.rs $patch_dst/operators/iterate.rs
	cargo clean -p differential-dataflow --release
	cargo build -p differential-dataflow --release

	rm collection.rs*
	rm iterate.rs*

	# Build the project
	cargo build --release -j $build_workers
	popd

	$flowlog_exe --help
fi

pushd /usr/local/bin
wget -O csv2ddlog https://raw.githubusercontent.com/srinskit/cloudlab-auto/refs/heads/main/csv2ddlog.sh
popd

echo "SUCCESS"