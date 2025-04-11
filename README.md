# DLBench Automations for CloudLab

## Organization
### cloudlab-auto
This project folder contains the Datalog programs scripts that drive the benchmarking.

For every Datalog engine, there is a folder labelled `payload-<engine>` that contains Datalog programs in that engine's syntax.

### Benchmark Node
The benchmarks are executed on a CloudLab node with two AMD EPYC 7543 32-core processors (64 cores / 128 threads) and 256 GB of RAM. 

The node is instantiated with the CloudLab profile `dlbench-small-lan`, which configures the node with the `Ubuntu 20.04.6 LTS` OS and installs the following Datalog engines:
1. FlowLog
1. Souffle
1. DDLog
1. RecStep

The profile also mounts the remote dataset storage to the benchmark node at `/remote/input`.

### Dataset Storage
The dataset for the benchmarks are stored remotely. The dataset cannot be packaged along with the base OS because of the size constraints in an image-backed dataset. 

The CloudLab profile `dlbench-small-lan` mounts the remote dataset storage to the benchmark node at `/remote/input`.

Prior to starting the benchmark, the automation scripts create a node-local copy of the dataset to avoid slow IO during benchmarking.

### Driver Node
A driver node launches the benchmark in the `Benchmark Node`, and collects the results. This could be your personal device for short benchmarks, or another CloudLab node for long runs. 

## Benchmarking
### Setup CloudLab Infra
1. Login to [CloudLab](https://www.cloudlab.us)
1. Navigate to the profile [dlbench-small-lan](https://www.cloudlab.us/show-profile.php?uuid=96137190-0ff5-11f0-828b-e4434b2381fc), click on `Instantiate`
1. Select the `physical node type` as `r6525` from the `CloudLab Clemson` cluster.
