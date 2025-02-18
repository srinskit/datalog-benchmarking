#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/ddlog
build=1
build_workers=$(nproc)
workers_low=4
workers_high=64

rust_v=1.76

source $SRC/rust_env
source $SRC/ddlog_env

killall cargo || true
rustup toolchain install $rust_v

ddlog_prog_build() {
	local dl_prog="$1"
	ddlog -i "$dl".dl
	pushd "$dl"_ddlog
	cargo +$rust_v build --release --quiet
	popd
	echo "$dl"_ddlog/target/release/"$dl"_cli
}

dl=sg
exe=$(ddlog_prog_build $dl)
dlbench run "./$exe -w $workers_low < $DATA/G5K-0.001/arc.in" "sg-G5K-$workers_low-ddlog"
dlbench run "./$exe -w $workers_high < $DATA/G5K-0.001/arc.in" "sg-G5K-$workers_high-ddlog"

dl=andersen
exe=$(ddlog_prog_build $dl)
dlbench run "./$exe -w $workers_low < $DATA/andersen/500000/data.ddin" "andersen-500000-$workers_low-ddlog"
dlbench run "./$exe -w $workers_high < $DATA/andersen/500000/data.ddin" "andersen-500000-$workers_high-ddlog"