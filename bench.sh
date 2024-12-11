#!/bin/bash

# Sample benchmark script that benchmarks a Rust project "hw_timely"

source rust_env
cd hw_timely
cargo build --release
dlbench run 'target/release/hw_timely 10000000 -w3'