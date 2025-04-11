#!/bin/bash

# Exit script on error
set -e
PS4=':$LINENO+'
SRC=/opt
DATA=/data/input/ddlog
build_workers=$(nproc)
prev_dl=""
cmpl_time=0
exe=""
rust_v=1.76

source $SRC/rust_env
source $SRC/ddlog_env
source targets.sh

ddlog_prog_build() {
	local dl_prog="$1"
	rm -rf *_ddlog || true
	ddlog -i "$dl".dl
	pushd "$dl"_ddlog > /dev/null
	killall cargo || true > /dev/null
	RUSTFLAGS=-Awarnings cargo +$rust_v build --release --quiet -j $build_workers > /dev/null
	popd > /dev/null
	exe="$dl"_ddlog/target/release/"$dl"_cli
}

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"D"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			tag="$dl"_"$ds"_"$w"_ddlog
			tag="${tag//\//-}"

			# Build program
			if [ "$prev_dl" != "$dl" ]; then
				start=$(date +%s.%N)
				ddlog_prog_build $dl
				end=$(date +%s.%N)
				cmpl_time=$(echo "$end - $start" | bc)

				prev_dl="$dl"
			fi

			printf "CompileTime: %.2f\n" "$cmpl_time" >$tag.info

			killall $exe || true > /dev/null
			cmd="./$exe -w $w < $DATA/$dd/$ds/data.ddin"

			sync && sysctl vm.drop_caches=3
			set +e
			/usr/bin/time -f "LinuxRT: %e" timeout 600s dlbench run "$cmd" "$tag" 2>>$tag.info
			ret=$?
			set -e

			# Evaluate result
			if [[ $ret == 0 ]]; then
				echo "Status: CMP" >>$tag.info
			elif [[ $ret == 124 ]]; then
				echo "Status: TOUT" >>$tag.info
			elif [[ $ret == 137 ]]; then
				echo "Status: OOM" >>$tag.info
			else
				echo "Status: DNF" >>$tag.info
			fi

			sed -n "s/.*$key\", .size = \(.*\)}/DLOut: \1/Ip" $tag*.out >>$tag.info
			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
		done
	fi

done

rm -rf *_ddlog || true
