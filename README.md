# CloudLab & DLBench Automations

## Setup

### Option 1: Use Disk Image

* Create a VM from the CloudLab disk image `dlbench-ubu20-v0.1` or CloudLab profile `dlbench-small-lan` for the benchmark.
* The disk image was prepared by running executing `sudo ./setup.sh` on a `small-lan` VM (Ubuntu 20.04).
* It has the following tools installed:
  * Rust (TODO: which version?)
  * DLBench
  * Souffle (TODO)
  * DDLog (TODO)
  * RecStep (TODO)

URN for the disk image: `urn:publicid:IDN+wisc.cloudlab.us+image+lpad-PG0:dlbench-ubu20-v0.1`

### Option 2: BYOE

Bring your own environment by executing `setup.sh` or equivalent manually on the VM to install DLBench and the target project's dependencies.

## Benchmark

## deploy.sh

### Usage

```sh
./deploy.sh <project-path> <bench.sh> <username@vm.cloudlab.us> <ssh-key>
```

* `project-path`: Path to the project / program to be benchmarked. This directory / file will be copied to the working directory of the VM. This could be your Rust project, a binary, etc.
* `bench.sh`: Script that is executed in the VM's working directory to start the benchmarking. This could also contain some setup jobs like build. See below for a sample script.
* `username@vm.cloudlab.us`: The VM host address to SSH into.
* `ssh-key`: The SSH key to login to the host with.

### Example

```
./deploy.sh ../hw_timely bench.sh srinskit@xyz.wisc.cloudlab.us ~/wisc-key
```

#### Sample bench.sh

```sh
#!/bin/bash

# Builds and benchmarks a Rust project "hw_timely"

cd hw_timely

# load rust env vars and build
source rust_env 
cargo build --release

dlbench run 'target/release/hw_timely 10000000 -w3'
```

```sh
$ ./deploy.sh ../hw_timely bench.sh srinskit@xyz.wisc.cloudlab.us ~/wisc-key

    Finished `release` profile [optimized] target(s) in 0.14s
System CPU count: 40
System MEM total: 187
System MEM avail: 185
System MEM usage: 1.0
Started process: hw_timely
Run name: dlbench-hw_timely-2024-12-10T20:10:21
Logging stats to: dlbench-hw_timely-2024-12-10T20:10:21.log
STATS: (8500, 259.3, 2163429376, 10963)
CPU Time: pcputimes(user=21.85, system=3.32, children_user=0.0, children_system=0.0, iowait=0.0)
CPU Time: 25.17
```

## deploy-dist.sh

TODO: `deploy.sh` but for a cluster of VMs.


ssh-add $SSH_KEY
