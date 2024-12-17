#!/bin/bash

# Rough cleanup, for testing only

WORK_DIR=/opt
SRC=/usr/local/src

pip uninstall dlbench -y
rustup self uninstall -y
apt remove python3-pip -y

rm $SRC/dlbench -rf
rm $SRC/rust -rf
rm $WORK_DIR/rust_env