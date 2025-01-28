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
	echo "[img-setup] dlbench exists, skipping install."
else
	git clone --depth=1 https://github.com/srinskit/dlbench $SRC/dlbench
	pip install $SRC/dlbench/
fi

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

	# TODO: install a specific toolchain

	# Save rust env for load during login
	echo "export CARGO_HOME=$SRC/rust" >$WORK_DIR/rust_env
	echo "export RUSTUP_HOME=$SRC/rust" >>$WORK_DIR/rust_env
	echo "export PATH=$CARGO_HOME/bin:\$PATH" >>$WORK_DIR/rust_env
	source $WORK_DIR/rust_env
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

	echo "export DDLOG_HOME=$SRC/ddlog" > $WORK_DIR/ddlog_env
	echo "export PATH=$PATH:$SRC/ddlog/bin" >> $WORK_DIR/ddlog_env
	source $WORK_DIR/ddlog_env
fi

ddlog --version