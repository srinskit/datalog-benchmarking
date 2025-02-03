#!/bin/bash

# Setup a base CloudLab Ubuntu 20.04 image for our experiments

# Exit script on error
set -e

WORK_DIR=/opt
SRC=/usr/local/src

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
	echo "[img-setup] dlbench exists, attempting update."
	chown -R $USER $SRC/dlbench
	pushd $SRC/dlbench
	git pull origin main
	popd
else
	git clone --depth=1 https://github.com/srinskit/dlbench $SRC/dlbench
fi

pip install $SRC/dlbench/

dlbench --help

# Install Rust

source $WORK_DIR/rust_env || true

if command -v cargo >/dev/null 2>&1; then
	echo "[img-setup] rust exists, skipping install."
else
	export CARGO_HOME=$SRC/rust
	export RUSTUP_HOME=$SRC/rust
	RUST_OPS="-q -y --profile minimal"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- $RUST_OPS

	# Save rust env for load during login
	echo "export CARGO_HOME=$SRC/rust" >$WORK_DIR/rust_env
	echo "export RUSTUP_HOME=$SRC/rust" >>$WORK_DIR/rust_env
	echo "export PATH=$CARGO_HOME/bin:\$PATH" >>$WORK_DIR/rust_env
	source $WORK_DIR/rust_env

	# For DDLog
	rustup toolchain install 1.76
fi

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
	tar -xf ddlog-v1.2.3-20211213235218-Linux.tar.gz -C $SRC

	echo "export DDLOG_HOME=$SRC/ddlog" >$WORK_DIR/ddlog_env
	echo "export PATH=$PATH:$SRC/ddlog/bin" >>$WORK_DIR/ddlog_env
	source $WORK_DIR/ddlog_env
fi

ddlog --version

# Install RecStep

## Install GRPC

if [[ ! -d $SRC/grpc ]]; then
	export CC=/usr/bin/clang
	export CXX=/usr/bin/clang++
	apt -qq update -y
	apt -qq install -y clang
	apt -qq install -y clang++
	apt -qq install -y cmake

	git clone --depth=1 -b v1.28.1 https://github.com/grpc/grpc $SRC/grpc

	cd $SRC/grpc
	git submodule update --init

	make --silent -j $build_workers
	make --silent install

	cd third_party/protobuf
	make --silent install
fi

## Install QuickStep by copying build from Ubuntu 18 LTS manually as a folder $SRC/quickstep

## Install RecStep

if [[ ! -d $SRC/RecStep ]]; then
	apt -qq update -y
	apt -qq install -y python3-pip python-dev build-essential libjpeg-dev zlib1g-dev
	pip3 install --upgrade pip
	pip3 install cython
	pip3 install matplotlib
	pip3 install psutil
	pip3 install antlr4-python3-runtime==4.8
	pip3 install networkx

	git clone --depth=1 https://github.com/Hacker0912/RecStep $SRC/RecStep

	# Point config to quickstep
	sed -i "s|/fastdisk/quickstep-datalog/build|$SRC/quickstep|" $SRC/RecStep/Config.json

	# Install CLI and env
	echo "#! $(which python3)" > recstep
	cat interpreter.py >> recstep
	chmod +x recstep
	echo "export CONFIG_FILE_DIR=$SRC/RecStep" >$WORK_DIR/recstep_env
	echo "export PATH=$PATH:$SRC/RecStep" >>$WORK_DIR/recstep_env
	source $WORK_DIR/recstep_env
fi

source $WORK_DIR/recstep_env
recstep --help
