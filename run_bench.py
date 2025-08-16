#!/usr/bin/env python3

import os
import subprocess
import sys
import glob
import re
import json
import time
import argparse
import logging
import csv
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global constants
DATA = "/data/input"


def get_payload_dir(engine_variant):
    """Get the correct payload directory for the engine"""
    engine_to_payload = {
        "D": "payload-ddlog",
        "F0": "payload-flowlog",
        "F1": "payload-flowlog1",
        "F2": "payload-flowlog2",
        "Si": "payload-souffle",
        "Sc": "payload-souffle",
        "R": "payload-recstep",
        "Q": "payload-duckdb",
        "U": "payload-umbra",
    }
    return engine_to_payload.get(engine_variant, ".")


def load_targets(targets_file="targets.json"):
    """Load benchmark targets from specified file"""
    required_fields = ["program", "dataset", "output_relation", "engines", "threads"]

    try:
        with open(targets_file, "r") as f:
            targets = json.load(f)

        valid_targets = []
        for i, target in enumerate(targets):
            missing_fields = [field for field in required_fields if field not in target]
            if missing_fields:
                logger.error(f"Target {i} missing fields: {missing_fields}")
                sys.exit(1)

            if target.get("disabled", False):
                continue

            valid_targets.append(target)

        return valid_targets
    except FileNotFoundError:
        logger.error(f"{targets_file} not found")
        sys.exit(1)


def run_command(cmd, timeout_sec=None):
    """Run command and return (exit_code, stdout, stderr)"""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout_sec
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 124, "", ""


def clear_caches():
    """Clear system caches for consistent benchmarking"""
    subprocess.run("sync", shell=True)
    subprocess.run("sysctl vm.drop_caches=3", shell=True)


def get_status_from_exit_code(exit_code):
    """Map exit codes to status strings"""
    if exit_code == 0:
        return "CMP"
    elif exit_code == 124:
        return "TOUT"
    elif exit_code == 137:
        return "OOM"
    else:
        return "DNF"


def extract_metric_regex(pattern, files, case_insensitive=True):
    """Extract metric from files using regex pattern"""
    flags = re.IGNORECASE if case_insensitive else 0
    for file_path in glob.glob(files):
        try:
            with open(file_path, "r") as f:
                content = f.read()
            match = re.search(pattern, content, flags)
            if match:
                return match.group(1) if match.groups() else match.group(0)
        except FileNotFoundError:
            continue
    return ""


def extract_dl_out(engine_variant, key, tag, exit_code):
    """Extract dl_out metric for all engines"""
    if engine_variant == "D":
        return extract_metric_regex(rf"{key}\", .size = (\d+)", f"{tag}*.out")
    elif engine_variant in ["F0", "F1", "F2"]:
        return extract_metric_regex(
            rf"Delta of.*\[{key}\]: \(\(\), \(\), (\d+)\)", f"{tag}*.out"
        )
    elif engine_variant in ["Si", "Sc"]:
        return extract_metric_regex(rf"{key}\s+(\d+)", f"{tag}*.out")
    elif engine_variant == "R":
        if exit_code != 0:
            return ""
        # Wait for quickstep to exit
        while (
            subprocess.run(
                "pgrep quickstep", shell=True, capture_output=True
            ).returncode
            == 0
        ):
            time.sleep(1)
        # Query quickstep for results
        SRC = "/opt"
        for k in key.split(","):
            query_cmd = f"python3 {SRC}/RecStep/quickstep_shell.py --mode interactive"
            query_input = f"select '{k}' as Rel, count(*) from {k};"
            result = subprocess.run(
                query_cmd, input=query_input, shell=True, capture_output=True, text=True
            )
            match = re.search(rf"\|\s*{k}\s*\|\s*(\d+)\s*\|", result.stdout)
            if match:
                return match.group(1)
        return ""
    elif engine_variant == "Q":
        for file_path in glob.glob(f"{tag}*.out"):
            try:
                with open(file_path, "r") as f:
                    content = f.read()
                lines = content.split("\n")
                for i, line in enumerate(lines):
                    if key in line and i + 3 < len(lines):
                        match = re.search(r"\d+", lines[i + 3])
                        if match:
                            return match.group(0)
            except FileNotFoundError:
                continue
        return ""
    elif engine_variant == "U":
        for file_path in glob.glob(f"{tag}*.out"):
            try:
                with open(file_path, "r") as f:
                    lines = f.readlines()
                for i, line in enumerate(lines):
                    if key.lower() in line.lower() and i + 1 < len(lines):
                        return lines[i + 1].strip()
            except FileNotFoundError:
                continue
        return ""
    return ""


def find_rate_drop_time(rows, threshold):
    """Find the earliest time when IO rate drops below the threshold, starting from the latest time."""
    if not rows:
        return None
    
    rates = []
    prev_time = 0.0
    prev_io = 0

    for row in rows:
        time_val = float(row["Time"])
        io_reads = int(row["IO Reads"])

        time_diff_s = (time_val - prev_time)
        io_rate_s = (io_reads - prev_io) / time_diff_s if time_diff_s > 0 else 0
        rates.append((time_val, io_rate_s))

        prev_time = time_val
        prev_io = io_reads

    # Start from the end and go backwards
    for i in range(len(rates) - 1, -1, -1):
        time_val, rate = rates[i]
        if rate > threshold:
            return time_val

    return None


def extract_load_time(engine_variant, tag):
    """Extract load_time metric for all engines"""
    if engine_variant in ["Si", "Sc", "F0", "F1", "F2"]:
        # For both Souffle and FlowLog, use IO rate drop technique from .log file
        log_file = f"{tag}.log"
        threshold = 1000  # bytes/s threshold
        
        try:
            with open(log_file, "r") as f:
                csv_reader = csv.DictReader(f)
                rows = list(csv_reader)
            
            return find_rate_drop_time(rows, threshold)
        except (FileNotFoundError, KeyError, ValueError):
            return None
    
    elif engine_variant == "U":
        for file_path in glob.glob(f"{tag}*.out"):
            try:
                with open(file_path, "r") as f:
                    lines = f.readlines()
                for i, line in enumerate(lines):
                    if "load_time" in line.lower() and i + 1 < len(lines):
                        try:
                            return float(lines[i + 1].strip())
                        except ValueError:
                            return None
            except FileNotFoundError:
                continue
        return None
    
    return None


def extract_profiler_load_time(engine_variant, tag):
    """Extract profiler load time for flowlog and souffle engines"""
    if engine_variant in ["F0", "F1", "F2"]:
        return _get_flowlog_loadtime(f"{tag}.out")
    elif engine_variant in ["Si", "Sc"]:
        return _get_souffle_loadtime(f"{tag}.profile")
    return None


def _get_flowlog_loadtime(out_file_path):
    """Extract load time from FlowLog .out file"""
    if not os.path.exists(out_file_path):
        return None
        
    last_timestamp = None
    pattern = re.compile(r"(\d+\.\d+)(ms|s):\s*Data loaded for")
    
    try:
        with open(out_file_path, "r") as f:
            for line in f:
                match = pattern.search(line)
                if match:
                    value = float(match.group(1))
                    unit = match.group(2)
                    if unit == "ms":
                        value = value / 1000.0
                    last_timestamp = value
    except (FileNotFoundError, ValueError):
        return None
        
    return last_timestamp


def _get_souffle_loadtime(profile_file_path):
    """Extract load time from Souffle .profile file"""
    if not os.path.exists(profile_file_path):
        return None
        
    try:
        with open(profile_file_path, 'r') as f:
            data = json.load(f)
        
        relations = data["root"]["program"]["relation"]
        total_loadtime = 0
        
        for relation_name, relation_data in relations.items():
            if "loadtime" in relation_data:
                loadtime = relation_data["loadtime"]
                start_time = loadtime["start"]
                end_time = loadtime["end"]
                duration = (end_time - start_time) / 1000000  # Convert to seconds
                total_loadtime += duration
        
        return total_loadtime
        
    except (KeyError, FileNotFoundError, json.JSONDecodeError):
        return None


def benchmark_ddlog(program_path, dataset_path, workers, tag, timeout_sec, payload_dir):
    """Benchmark DDLog engine"""
    base_program = Path(program_path).name
    compile_time = 0

    # Build program if needed
    exe = f"{payload_dir}/{base_program}_ddlog/target/release/{base_program}_cli"
    if not os.path.exists(exe):
        start_time = time.time()
        subprocess.run(f"ddlog -i {payload_dir}/{program_path}.dl", shell=True)
        subprocess.run(
            f"RUSTFLAGS=-Awarnings cargo build --release --quiet",
            shell=True,
            cwd=f"{payload_dir}/{base_program}_ddlog",
        )
        compile_time = time.time() - start_time

    cmd = f"{exe} -w {workers} < {DATA}/{dataset_path}/data.ddin"

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}"'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, compile_time, runtime


def benchmark_flowlog(
    program_path, dataset_path, workers, tag, timeout_sec, payload_dir, variant="F0"
):
    """Benchmark FlowLog engine"""

    if variant == "F0":
        exe = "/opt/FlowLogTest/target/release/executing"
    elif variant == "F1":
        exe = "/data/FlowLogTest3/target/release/executing"
    elif variant == "F2":
        exe = "/data/FlowLogTest2/target/release/executing"

    cmd = f"{exe} --program {payload_dir}/{program_path}.dl --facts {DATA}/{dataset_path} --csvs . --workers {workers}"

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}"'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, None, runtime


def benchmark_souffle(
    program_path, dataset_path, workers, tag, timeout_sec, payload_dir, variant
):
    """Benchmark Souffle engine"""
    assert variant in ["Si", "Sc"], f"Invalid variant: {variant}"
    compile_time = None
    runtime = None

    if variant == "Si":
        cmd = f"souffle {payload_dir}/{program_path}.dl -F {DATA}/{dataset_path} -D . -j {workers} -p {tag}.profile"
    elif variant == "Sc":
        exe = "souffle_cmpl"

        if os.path.exists(exe):
            os.remove(exe)

        start_time = time.time()
        result = subprocess.run(
            f"souffle -o {exe} {payload_dir}/{program_path}.dl",
            shell=True,
            capture_output=True,
            text=True,
        )

        compile_time = time.time() - start_time

        if result.returncode != 0:
            logger.error(
                f"Souffle compilation failed with return code {result.returncode}: {result.stderr}"
            )
            return result.returncode, result.stderr, compile_time, runtime

        assert os.path.exists(
            exe
        ), f"Executable {exe} not found after successful compilation"

        cmd = f"./{exe} -F {DATA}/{dataset_path} -D . -j {workers}"

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}"'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, compile_time, runtime


def benchmark_recstep(program_path, dataset_path, workers, tag, timeout_sec, payload_dir):
    """Benchmark RecStep engine"""

    cmd = f"recstep --program {payload_dir}/{program_path}.dl --input {DATA}/{dataset_path} --jobs {workers}"

    # Prime the benchmark
    run_command(cmd, 5)

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}" --monitor quickstep_cli_shell'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, None, runtime


def benchmark_duckdb(program_path, dataset_path, workers, tag, timeout_sec, payload_dir):
    """Benchmark DuckDB engine"""
    DB = "test.db"

    # Setup
    subprocess.run(f"ln -sf {DATA}/{dataset_path} /dataset", shell=True)
    subprocess.run(f"rm -f {DB}", shell=True)
    subprocess.run(f"duckdb {DB} < {payload_dir}/duckdb_config.sql", shell=True)

    cmd = f"duckdb {DB} < {payload_dir}/{program_path}.sql"

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}"'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, None, runtime


def benchmark_umbra(program_path, dataset_path, workers, tag, timeout_sec, payload_dir):
    """Benchmark Umbra engine"""

    cmd = f"""docker run \\
        --rm \\
        --cpuset-cpus='0-{workers}' \\
        -v '{DATA}/{dataset_path}:/data' \\
        -v '{os.getcwd()}/{payload_dir}:/payload' \\
        --user root \\
        umbradb/umbra:25.07.1 \\
        /usr/local/bin/umbra-sql -createdb 'test.db' '/payload/{program_path}.sql'"""

    clear_caches()
    start_time = time.time()
    dlbench_cmd = f'dlbench run "{cmd}" "{tag}"'
    exit_code, stdout, stderr = run_command(dlbench_cmd, timeout_sec)
    runtime = time.time() - start_time

    return exit_code, stderr, None, runtime


def main():
    parser = argparse.ArgumentParser(description="Run Datalog benchmarks")
    parser.add_argument(
        "engines", help="Comma-separated engine list (e.g., D,F0,Si,Sc,U)"
    )
    parser.add_argument(
        "--targets", default="targets.json", help="Targets file (default: targets.json)"
    )
    args = parser.parse_args()

    # Parse CLI engines from comma-separated string
    cli_engines = {
        engine.strip() for engine in args.engines.split(",") if engine.strip()
    }

    # Disable swap
    subprocess.run("swapoff -a", shell=True)
    subprocess.run("docker pull umbradb/umbra:25.07.1", shell=True)

    # Load targets
    targets = load_targets(args.targets)

    for target in targets:
        program_path = target["program_path"]
        dataset_path = target["dataset_path"]
        key = target["output_relation"]
        target_engines = set(target["engines"])
        threads = target["threads"]
        timeout = target.get("timeout", 600)

        ds = Path(dataset_path).name
        timeout_sec = int(timeout)

        # Find engines to test: intersection of CLI engines and target engines
        engines_to_test = cli_engines & target_engines

        # Run for each engine that should be tested
        for engine_variant in engines_to_test:

            for workers in threads:
                # Create tag
                engine_names = {
                    "D": "ddlog",
                    "F0": "flowlog",
                    "F1": "flowlog",
                    "F2": "flowlog",
                    "Si": "souffle-intptr",
                    "Sc": "souffle-cmpl",
                    "R": "recstep",
                    "Q": "duckdb",
                    "U": "umbra",
                }

                engine_name = engine_names.get(engine_variant, engine_variant)
                program_name = target["program"]
                dataset_name = target["dataset"]
                plan_set = target["plan_set"]
                
                logger.info(
                    f"program: {program_name}, plan_set: {plan_set} dataset: {dataset_name}, workers: {workers}, engine: {engine_name}"
                )

                tag = f"{program_name}_{plan_set}_{dataset_name}_{workers}_{engine_name}"

                # Get payload directory
                payload_dir = get_payload_dir(engine_variant)

                # Run appropriate benchmark
                compile_time = None
                try:
                    if engine_variant == "D":
                        exit_code, stderr, compile_time, runtime = benchmark_ddlog(
                            program_path, dataset_path, workers, tag, timeout_sec, payload_dir
                        )
                    elif engine_variant in ["F0", "F1", "F2"]:
                        exit_code, stderr, compile_time, runtime = benchmark_flowlog(
                            program_path,
                            dataset_path,
                            workers,
                            tag,
                            timeout_sec,
                            payload_dir,
                            engine_variant,
                        )
                    elif engine_variant in ["Si", "Sc"]:
                        exit_code, stderr, compile_time, runtime = benchmark_souffle(
                            program_path,
                            dataset_path,
                            workers,
                            tag,
                            timeout_sec,
                            payload_dir,
                            engine_variant,
                        )
                    elif engine_variant == "R":
                        exit_code, stderr, compile_time, runtime = benchmark_recstep(
                            program_path, dataset_path, workers, tag, timeout_sec, payload_dir
                        )
                    elif engine_variant == "Q":
                        exit_code, stderr, compile_time, runtime = benchmark_duckdb(
                            program_path, dataset_path, workers, tag, timeout_sec, payload_dir
                        )
                    elif engine_variant == "U":
                        exit_code, stderr, compile_time, runtime = benchmark_umbra(
                            program_path, dataset_path, workers, tag, timeout_sec, payload_dir
                        )
                    else:
                        continue

                except Exception as e:
                    logger.error(f"Error running {engine_variant} benchmark: {e}")
                    continue

                # Write stderr to tag.err file
                with open(f"{tag}.err", "w") as f:
                    f.write(stderr)

                # Extract dl_out, load_time, and profiler_load_time
                dl_out = extract_dl_out(engine_variant, key, tag, exit_code)
                load_time = extract_load_time(engine_variant, tag)
                profiler_load_time = extract_profiler_load_time(engine_variant, tag)

                # Convert metrics to appropriate types
                correctness_output = int(dl_out) if dl_out.isdigit() else None

                # Write JSON file
                result_data = {
                    "status": get_status_from_exit_code(exit_code),
                    "runtime": round(runtime, 2) if runtime is not None else None,
                    "correctness_output": correctness_output,
                    "load_time": round(load_time, 2) if load_time is not None else None,
                    "compile_time": round(compile_time, 2) if compile_time is not None else None,
                    "profiler_load_time": round(profiler_load_time, 2) if profiler_load_time is not None else None,
                }

                with open(f"{tag}.json", "w") as f:
                    json.dump(result_data, f, indent=2)


if __name__ == "__main__":
    main()
