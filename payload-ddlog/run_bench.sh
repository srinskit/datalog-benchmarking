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
	pushd "$dl"_ddlog > /dev/null
	killall cargo || true
	RUSTFLAGS=-Awarnings cargo +$rust_v build --release --quiet -j $build_workers
	popd > /dev/null
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
			tag="$dl"_"$ds"_"$w"_ddlog

			set +e
			timeout 600s dlbench run "$cmd" "$tag"
			ret=$?
			set -e

			if [[ $ret == 0 ]]; then
				echo CMP >$tag.info
			elif [[ $ret == 127 || $ret == 137 ]]; then
				echo T/O >$tag.info
			else
				echo DNF >$tag.info
			fi
		done
	fi

done

rm -rf *_ddlog || true
