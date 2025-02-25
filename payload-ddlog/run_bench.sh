#!/bin/bash

# Exit script on error
set -e
PS4=':$LINENO+'
SRC=/opt
DATA=/data/input/ddlog
build_workers=$(nproc)
prev_dl=""
exe=""
rust_v=1.76

source $SRC/rust_env
source $SRC/ddlog_env
source bench_targets.sh

ddlog_prog_build() {
	local dl_prog="$1"
	ddlog -i "$dl".dl
	pushd "$dl"_ddlog
	killall cargo || true
	RUSTFLAGS=-Awarnings cargo +$rust_v build --release --quiet -j $build_workers
	popd
	echo "$dl"_ddlog/target/release/"$dl"_cli
}

for target in "${targets[@]}"; do
	read -r dl dd ds <<<"$target"

	# Build program
	if [ "$prev_dl" != "$dl" ]; then
		exe=$(ddlog_prog_build $dl)
		prev_dl="$dl"
	fi

	for w in "${workers[@]}"; do
		killall $exe || true
		echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
		cmd="./$exe -w $w < $DATA/$dd/$ds/data.ddin"
		dlbench run "$cmd" "$dl"_"$ds"_"$w"_ddlog
	done
done
