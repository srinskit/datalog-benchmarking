#!/bin/bash

# Setup a base CloudLab Ubuntu 20.04 image for our experiments

WORK_DIR=/opt
SRC=/usr/local/src

cd $WORK_DIR

# Install PIP
apt update
apt install python3-pip -y

# Install DL Bench

git clone --depth=1 https://github.com/srinskit/dlbench $SRC/dlbench
pip install $SRC/dlbench/

# Install Rust into our workspace

export CARGO_HOME=$SRC/rust
export RUSTUP_HOME=$SRC/rust
RUST_OPS="-q -y --profile minimal"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- $RUST_OPS

# TODO: install a specific toolchain

# Save rust env for load during login
echo "
export CARGO_HOME=$SRC/rust
export RUSTUP_HOME=$SRC/rust
export PATH=$CARGO_HOME/bin:\$PATH
" > $WORK_DIR/rust_env

source $WORK_DIR/rust_env

# Verify installations
dlbench --help
rustc --version
cargo --version

# TODO: look at return codes and handle errors