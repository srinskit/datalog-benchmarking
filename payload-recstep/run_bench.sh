#!/bin/bash

# Exit script on error
set -e

SRC=/opt
DATA=/data/input/souffle

source $SRC/recstep_env
source targets.sh

for target in "${targets[@]}"; do
	read -r dl dd ds key charmap <<<"$target"

	if [[ "$charmap" == *"R"* ]]; then
		for w in "${workers[@]}"; do
			echo "[run_bench] program: $dl, dataset: $dd/$ds, workers: $w"
			cmd="recstep --program $dl.dl --input $DATA/$dd/$ds --jobs $w"
			tag="$dl"_"$ds"_"$w"_recstep
			tag="${tag//\//-}"

			set +e

			sleep 2
			rm -rf qsstor log
			sync && sysctl vm.drop_caches=3

			# Prime the benchmark
			timeout 5s $cmd >/dev/null 2>&1

			/usr/bin/time -f "LinuxRT: %e" timeout 600s dlbench run "$cmd" "$tag" --monitor quickstep_cli_shell 2>$tag.info
			ret=$?
			echo $ret
			set -e

			# Evaluate result
			if [[ $ret == 0 ]]; then
				echo "Status: CMP" >>$tag.info

				set +e
				cp $SRC/RecStep/Config.json .
				IFS=',' read -ra key_arr <<<$key

				while pgrep "quickstep" >/dev/null; do
					echo "[run_bench] waiting for quickstep to exit"
					sleep 1
				done

				echo "[run_bench] attempting to query quickstep"

				for k in "${key_arr[@]}"; do
					python3 $SRC/RecStep/quickstep_shell.py --mode interactive <<<"select '$k' as Rel, count(*) from $k;" >>$tag.out 2>&1
					sed -n "s/[| ]*$k[| ]*\([0-9]\+\)[| ]*/DLOut: \1/Ip" $tag.out >>$tag.info
				done

				rm Config.json
				set -e

			elif [[ $ret == 124 ]]; then
				echo "Status: TOUT" >>$tag.info
			elif [[ $ret == 137 ]]; then
				echo "Status: OOM" >>$tag.info
			else
				echo "Status: DNF" >>$tag.info
			fi

			echo "DLBenchRT:" $(tail -n 1 $tag*.log | cut -d ',' -f 1) >>$tag.info
			done
	fi
done
