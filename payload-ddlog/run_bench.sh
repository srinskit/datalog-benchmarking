#!/bin/bash

# Exit script on error
set -e

source ../rust_env
source ../ddlog_env

PAYLOAD_DIR=$(pwd)
build=1
build_workers=$(nproc)
workers=$(nproc)
dl_program=csda.dl
exe=csda_cli
rust_v=1.76

killall cargo || true

if [[ $build == 1 ]]; then
	rustup toolchain install $rust_v

	ddlog -i $dl_program
	pushd csda_ddlog
	cargo +$rust_v build --release --quiet
	popd

	mkdir -p experiment
	cp csda_ddlog/target/release/$exe experiment
	cp postgresql/input.prog experiment
fi

# TODO: don't duplicate input

pushd experiment
dlbench run "./$exe -w $workers < input.prog"
