#!/bin/bash

# Exit script on error
set -e


SRC=/opt
DATA=/data/input/ddlog
build=1
build_workers=$(nproc)
workers_low=4
workers_high=64
dl=sg
dl_program="$dl".dl
exe="$dl"_ddlog/target/release/"$dl"_cli
rust_v=1.76

source $SRC/rust_env
source $SRC/ddlog_env

killall cargo || true

if [[ $build == 1 ]]; then
	rustup toolchain install $rust_v

	ddlog -i $dl_program
	pushd "$dl"_ddlog
	cargo +$rust_v build --release --quiet
	popd
fi

dlbench run "./$exe -w $workers_low < $DATA/G5K-0.001/arc.in" "sg-$workers_low-ddlog"
dlbench run "./$exe -w $workers_high < $DATA/G5K-0.001/arc.in" "sg-$workers_high-ddlog"
