#!/bin/bash

# Exit script on error
set -e

WORK_DIR=/opt
SRC=/usr/local/src
build_workers=$(nproc)

source $WORK_DIR/recstep_env || true

if command -v recstep >/dev/null 2>&1; then
	echo "[img-setup] recstep exists, skipping install."
else
	# https://github.com/Hacker0912/quickstep-datalog

	apt -qq update -y
	apt -qq install -y clang-5.0
	apt -qq install -y clang++-5.0
	export CXX=/usr/bin/clang++-5.0
	export CC=/usr/bin/clang-5.0

	apt -qq install -y cmake
	cmake --version

	if [[ ! -d $SRC/grpc ]]; then
		git clone --depth=1 -b v1.28.1 https://github.com/grpc/grpc $SRC/grpc

		cd $SRC/grpc
		git submodule update --init

		make --silent -j $build_workers
		make --silent install

		cd third_party/protobuf
		make --silent install
	fi

	if [[ ! -d $SRC/quickstep ]]; then
		git clone --depth=1 -b recstep https://github.com/Hacker0912/quickstep-datalog $SRC/quickstep

		cd $SRC/quickstep
		git submodule init
		git submodule update

		pushd third_party
		./download_and_patch_prerequisites.sh
		popd

		cd build
		cmake -D CMAKE_C_COMPILER=$CC CMAKE_CXX_COMPILER=$CXX CMAKE_BUILD_TYPE=Release -D ENABLE_NETWORK_CLI=True ..
		make --silent -j $build_workers quickstep_cli_shell quickstep_client
	fi

	# https://github.com/Hacker0912/RecStep

	apt -qq install -y python3-pip python-dev build-essential libjpeg-dev zlib1g-dev
	pip3 install --upgrade pip
	pip3 install cython
	pip3 install matplotlib
	pip3 install psutil
	pip3 install antlr4-python3-runtime==4.8
	pip3 install networkx

	if [[ ! -d $SRC/RecStep ]]; then
		git clone --depth=1 https://github.com/Hacker0912/RecStep $SRC/RecStep
	fi

	cd $SRC/RecStep

	# Point config to quickstep
	sed -i "s|/fastdisk/quickstep-datalog/build|$SRC/quickstep|" $SRC/RecStep/Config.json

	# Install CLI and env
	echo "#! $(which python3)" >recstep
	cat interpreter.py >>recstep
	chmod +x recstep
	echo "export CONFIG_FILE_DIR=$SRC/RecStep" > $WORK_DIR/recstep_env
	echo "export PATH=$PATH:$SRC/RecStep" >> $WORK_DIR/recstep_env
	source $WORK_DIR/recstep_env
fi

recstep --help
