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
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"D"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"

			# Build program
			if [ "$prev_dl" != "$dl" ]; then
				rm -rf *_ddlog || true
				exe=$(ddlog_prog_build $dl)
				prev_dl="$dl"
			fi

			killall $exe || true
			cmd="./$exe -w $w < $DATA/$dd/$ds/data.ddin"
			dlbench run "$cmd" "$dl"_"$ds"_"$w"_ddlog
		done
	fi

done

rm -rf *_ddlog || true
