#!/usr/bin/env python3

import os
import subprocess
import sys
import glob
import re
import json
import time
import argparse
from pathlib import Path

def get_payload_dir(engine_variant):
    """Get the correct payload directory for the engine"""
    engine_to_payload = {
        'D': 'payload-ddlog',
        'F0': 'payload-flowlog',
        'F1': 'payload-flowlog1',
        'F2': 'payload-flowlog2',
        'Si': 'payload-souffle-intptr',
        'Sc': 'payload-souffle-cmpl',
        'R': 'payload-recstep',
        'Q': 'payload-duckdb',
        'U': 'payload-umbra'
    }
    return engine_to_payload.get(engine_variant, '.')

def load_targets():
    """Load benchmark targets from targets.json"""
    required_fields = ['program', 'dataset', 'output_relation', 'engines', 'threads']
    
    try:
        with open('targets.json', 'r') as f:
            targets = json.load(f)
        
        valid_targets = []
        for i, target in enumerate(targets):
            missing_fields = [field for field in required_fields if field not in target]
            if missing_fields:
                print(f"Error: Target {i} missing fields: {missing_fields}")
                sys.exit(1)
            
            if target.get('disabled', False):
                continue
                
            valid_targets.append(target)
        
        return valid_targets
    except FileNotFoundError:
        print("Error: targets.json not found")
        sys.exit(1)

def run_command(cmd, timeout_sec=None):
    """Run command and return (exit_code, stdout, stderr)"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout_sec)
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
            with open(file_path, 'r') as f:
                content = f.read()
            match = re.search(pattern, content, flags)
            if match:
                return match.group(1) if match.groups() else match.group(0)
        except FileNotFoundError:
            continue
    return ""

def get_last_field(files, delimiter=',', field=0):
    """Get specific field from last line of files"""
    for file_path in glob.glob(files):
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()
            if lines:
                last_line = lines[-1].strip()
                fields = last_line.split(delimiter)
                if len(fields) > field:
                    return fields[field]
        except FileNotFoundError:
            continue
    return ""

def run_ddlog_benchmark(dl, dp, key, w, tag, timeout_sec):
    """Run DDLog benchmark"""
    DATA = "/data/input"
    SRC = "/opt"
    payload_dir = get_payload_dir('D')
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    # Source environment
    subprocess.run(f"source {SRC}/rust_env && source {SRC}/ddlog_env", shell=True)
    
    # Build program if needed
    exe = f"{dl}_ddlog/target/release/{Path(dl).name}_cli"
    if not os.path.exists(exe):
        print(f"Building DDLog program: {dl}")
        subprocess.run(f"rm -rf *_ddlog", shell=True)
        subprocess.run(f"ddlog -i {dl}.dl", shell=True)
        subprocess.run(f"cd {dl}_ddlog && RUSTFLAGS=-Awarnings cargo build --release --quiet", shell=True)
    
    cmd = f"./{exe} -w {w} < {DATA}/{dp}/data.ddin"
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\""
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics
    dl_out = extract_metric_regex(rf"{key}\", .size = (\d+)", f"{tag}*.out")
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt

def run_flowlog_benchmark(dl, dp, key, w, tag, timeout_sec, variant="F0"):
    """Run FlowLog benchmark"""
    DATA = "/data/input"
    payload_dir = get_payload_dir(variant)
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    if variant == "F0":
        exe = "/opt/FlowLogTest/target/release/executing"
    elif variant == "F1":
        exe = "/data/FlowLogTest3/target/release/executing"
    elif variant == "F2":
        exe = "/data/FlowLogTest2/target/release/executing"
    
    cmd = f"{exe} --program {dl}.dl --facts {DATA}/{dp} --csvs . --workers {w}"
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\""
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics
    dl_out = extract_metric_regex(rf"Delta of.*\[{key}\]: \(\(\), \(\), (\d+)\)", f"{tag}*.out")
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt

def run_souffle_benchmark(dl, dp, key, w, tag, timeout_sec, variant="Si"):
    """Run Souffle benchmark"""
    DATA = "/data/input"
    payload_dir = get_payload_dir(variant)
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    if variant == "Si":
        cmd = f"souffle {dl}.dl -F {DATA}/{dp} -D . -j {w} -p {tag}.profile"
        engine_name = "souffle-intptr"
    elif variant == "Sc":
        exe = "souffle_cmpl"
        subprocess.run(f"souffle -o {exe} {dl}.dl", shell=True)
        cmd = f"./{exe} -F {DATA}/{dp} -D . -j {w}"
        engine_name = "souffle-cmpl"
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\""
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics
    dl_out = extract_metric_regex(rf"{key}\s+(\d+)", f"{tag}*.out")
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt

def run_recstep_benchmark(dl, dp, key, w, tag, timeout_sec):
    """Run RecStep benchmark"""
    DATA = "/data/input"
    SRC = "/opt"
    payload_dir = get_payload_dir('R')
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    subprocess.run(f"source {SRC}/recstep_env", shell=True)
    
    cmd = f"recstep --program {dl}.dl --input {DATA}/{dp} --jobs {w}"
    
    # Prime the benchmark
    subprocess.run(f"timeout 5s {cmd}", shell=True)
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\" --monitor quickstep_cli_shell"
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics for RecStep (special handling)
    dl_out = ""
    if exit_code == 0:
        # Wait for quickstep to exit
        while subprocess.run("pgrep quickstep", shell=True, capture_output=True).returncode == 0:
            time.sleep(1)
        
        # Query quickstep for results
        for k in key.split(','):
            query_cmd = f"python3 {SRC}/RecStep/quickstep_shell.py --mode interactive"
            query_input = f"select '{k}' as Rel, count(*) from {k};"
            result = subprocess.run(query_cmd, input=query_input, shell=True, capture_output=True, text=True)
            
            match = re.search(rf"\|\s*{k}\s*\|\s*(\d+)\s*\|", result.stdout)
            if match:
                dl_out = match.group(1)
                break
    
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt

def run_duckdb_benchmark(dl, dp, key, w, tag, timeout_sec):
    """Run DuckDB benchmark"""
    DATA = "/data/input"
    DB = "test.db"
    payload_dir = get_payload_dir('Q')
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    # Setup
    subprocess.run(f"ln -sf {DATA}/{dp} /dataset", shell=True)
    subprocess.run(f"rm -f {DB}", shell=True)
    subprocess.run(f"duckdb {DB} < duckdb_config.sql", shell=True)
    
    cmd = f"duckdb {DB} < {dl}.sql"
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\""
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics
    dl_out = ""
    for file_path in glob.glob(f"{tag}*.out"):
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            # Find key and get number from 3 lines after
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if key in line and i + 3 < len(lines):
                    match = re.search(r'\d+', lines[i + 3])
                    if match:
                        dl_out = match.group(0)
                        break
        except FileNotFoundError:
            continue
    
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt

def run_umbra_benchmark(dl, dp, key, w, tag, timeout_sec):
    """Run Umbra benchmark"""
    DATA = "/data/input"
    payload_dir = get_payload_dir('U')
    
    # Change to payload directory
    os.chdir(payload_dir)
    
    subprocess.run("docker pull umbradb/umbra:25.07.1", shell=True)
    
    cmd = f"""docker run \\
        --rm \\
        --cpuset-cpus='0-{w}' \\
        -v '{DATA}/{dp}:/data' \\
        -v '{os.getcwd()}:/payload' \\
        -w /payload \\
        --user root \\
        umbradb/umbra:25.07.1 \\
        /usr/local/bin/umbra-sql -createdb '/payload/test.db' '/payload/{dl}.sql'"""
    
    clear_caches()
    time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {timeout_sec}s dlbench run \"{cmd}\" \"{tag}\""
    exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
    
    # Extract metrics
    dl_out = ""
    load_time = ""
    for file_path in glob.glob(f"{tag}*.out"):
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()
            
            for i, line in enumerate(lines):
                if key.lower() in line.lower() and i + 1 < len(lines):
                    dl_out = lines[i + 1].strip()
                if "load_time" in line.lower() and i + 1 < len(lines):
                    load_time = lines[i + 1].strip()
        except FileNotFoundError:
            continue
    
    dlbench_rt = get_last_field(f"{tag}*.log")
    
    return exit_code, stderr, dl_out, dlbench_rt, load_time

def main():
    parser = argparse.ArgumentParser(description='Run Datalog benchmarks')
    parser.add_argument('engines', help='Engine character map (e.g., DF0RScSi, U, etc.)')
    args = parser.parse_args()
    
    engine_filter = args.engines
    original_dir = os.getcwd()
    
    # Disable swap
    subprocess.run("swapoff -a", shell=True)
    
    # Load targets
    targets = load_targets()
    
    for target in targets:
        dl = target['program']
        dp = target['dataset']
        key = target['output_relation']
        charmap = target['engines']
        threads = target['threads']
        timeout = target.get('timeout', '600s')
        
        ds = Path(dp).name
        timeout_sec = int(timeout.rstrip('s')) if timeout.endswith('s') else 600
        
        # Run for each engine in charmap that matches the filter
        for engine_char in charmap:
            if engine_char not in ['D', 'F', 'S', 'R', 'Q', 'U']:
                continue
                
            # Handle FlowLog variants
            if engine_char == 'F':
                if 'F0' in charmap:
                    engine_variant = 'F0'
                elif 'F1' in charmap:
                    engine_variant = 'F1'
                elif 'F2' in charmap:
                    engine_variant = 'F2'
                else:
                    engine_variant = 'F0'
            elif engine_char == 'S':
                if 'Si' in charmap:
                    engine_variant = 'Si'
                elif 'Sc' in charmap:
                    engine_variant = 'Sc'
                else:
                    engine_variant = 'Si'
            else:
                engine_variant = engine_char
            
            # Skip if this engine is not in charmap or engine filter
            if engine_variant not in charmap or engine_variant not in engine_filter:
                continue
            
            for w in threads:
                print(f"[run_bench] program: {dl}, dataset: {ds}, workers: {w}, engine: {engine_variant}")
                
                # Create tag
                engine_names = {
                    'D': 'ddlog',
                    'F0': 'flowlog',
                    'F1': 'flowlog',
                    'F2': 'flowlog',
                    'Si': 'souffle-intptr',
                    'Sc': 'souffle-cmpl',
                    'R': 'recstep',
                    'Q': 'duckdb',
                    'U': 'umbra'
                }
                
                engine_name = engine_names.get(engine_variant, engine_variant)
                tag = f"{dl}_{ds}_{w}_{engine_name}".replace('/', '-')
                
                # Run appropriate benchmark
                try:
                    if engine_variant == 'D':
                        exit_code, stderr, dl_out, dlbench_rt = run_ddlog_benchmark(dl, dp, key, w, tag, timeout_sec)
                        extra_metrics = {}
                    elif engine_variant in ['F0', 'F1', 'F2']:
                        exit_code, stderr, dl_out, dlbench_rt = run_flowlog_benchmark(dl, dp, key, w, tag, timeout_sec, engine_variant)
                        extra_metrics = {}
                    elif engine_variant in ['Si', 'Sc']:
                        exit_code, stderr, dl_out, dlbench_rt = run_souffle_benchmark(dl, dp, key, w, tag, timeout_sec, engine_variant)
                        extra_metrics = {}
                    elif engine_variant == 'R':
                        exit_code, stderr, dl_out, dlbench_rt = run_recstep_benchmark(dl, dp, key, w, tag, timeout_sec)
                        extra_metrics = {}
                    elif engine_variant == 'Q':
                        exit_code, stderr, dl_out, dlbench_rt = run_duckdb_benchmark(dl, dp, key, w, tag, timeout_sec)
                        extra_metrics = {}
                    elif engine_variant == 'U':
                        exit_code, stderr, dl_out, dlbench_rt, load_time = run_umbra_benchmark(dl, dp, key, w, tag, timeout_sec)
                        extra_metrics = {'load_time': load_time}
                    else:
                        continue
                        
                except Exception as e:
                    print(f"Error running {engine_variant} benchmark: {e}")
                    continue
                finally:
                    # Return to original directory
                    os.chdir(original_dir)
                
                # Write stderr to tag.err file
                with open(f"{tag}.err", 'w') as f:
                    f.write(stderr)
                
                # Extract LinuxRT from stderr
                linux_rt = 0.0
                if stderr:
                    rt_match = re.search(r'LinuxRT: ([0-9.]+)', stderr)
                    if rt_match:
                        linux_rt = float(rt_match.group(1))
                
                # Convert metrics to appropriate types
                correctness_output = int(dl_out) if dl_out.isdigit() else 0
                dlbench_runtime = float(dlbench_rt) if dlbench_rt else 0.0
                
                # Convert extra metrics
                converted_extra = {}
                for k, v in extra_metrics.items():
                    if k == 'load_time':
                        converted_extra[k] = float(v) if v and v.replace('.', '').isdigit() else 0.0
                    else:
                        converted_extra[k] = v
                
                # Write JSON file
                result_data = {
                    "status": get_status_from_exit_code(exit_code),
                    "runtime": linux_rt,
                    "correctness_output": correctness_output,
                    "dlbench_runtime": dlbench_runtime,
                    **converted_extra
                }
                
                with open(f"{tag}.json", 'w') as f:
                    json.dump(result_data, f, indent=2)

if __name__ == "__main__":
    main()