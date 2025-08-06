#!/usr/bin/env python3

import os
import subprocess
import sys
import glob
import re
import json
from pathlib import Path

def load_targets():
    """Load benchmark targets from targets.json"""
    try:
        with open('targets.json', 'r') as f:
            targets = json.load(f)
        # Filter out disabled targets
        return [t for t in targets if not t.get('disabled', False)]
    except FileNotFoundError:
        print("Error: targets.json not found")
        sys.exit(1)

def run_command(cmd, timeout_sec=None):
    """Run command and return (exit_code, stdout, stderr)"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout_sec)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 124, "", ""  # Timeout exit code

def clear_caches():
    """Clear system caches for consistent benchmarking"""
    subprocess.run("sync", shell=True)
    subprocess.run("sysctl vm.drop_caches=3", shell=True)

def get_status_from_exit_code(exit_code):
    """Map exit codes to status strings"""
    if exit_code == 0:
        return "CMP"  # Completed successfully
    elif exit_code == 124:
        return "TOUT"  # Timeout
    elif exit_code == 137:
        return "OOM"   # Out of memory
    else:
        return "DNF"   # Did not finish

def extract_metric(pattern, files, case_insensitive=True):
    """Extract metric from files using grep-like functionality"""
    flags = re.IGNORECASE if case_insensitive else 0
    for file_path in glob.glob(files):
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()
            
            for i, line in enumerate(lines):
                if re.search(pattern, line, flags):
                    if i + 1 < len(lines):
                        return lines[i + 1].strip()
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

def main():
    # Set data directory path
    DATA = "/data/input"
    
    # Disable swap to ensure consistent memory performance
    subprocess.run("swapoff -a", shell=True)
    subprocess.run("docker pull umbradb/umbra:25.07.1", shell=True)
    
    # Load benchmark targets
    targets = load_targets()
    
    # Iterate through each benchmark target
    for target in targets:
        # Extract target parameters from JSON
        dl = target['program']
        dp = target['dataset_path']
        key = target['output_relation']
        charmap = target['engines']
        threads = target['threads']
        tout = target.get('timeout', '600s')
        
        # Extract dataset name from path
        ds = Path(dp).name
        
        # Convert timeout to seconds for Python
        timeout_sec = int(tout.rstrip('s')) if tout.endswith('s') else 600
        
        # Check if this target supports Umbra (indicated by 'U' in charmap)
        if 'U' in charmap:
            # Parse comma-separated thread counts
            workers = threads.split(',')
            
            # Run benchmark for each worker count
            for w in workers:
                print(f"[run_bench] program: {dl}, dataset: {ds}, workers: {w}")
                
                # Create unique tag for this benchmark run
                tag = f"{dl}_{ds}_{w}_umbra"
                tag = tag.replace('/', '-')
                
                # Build Docker command for Umbra benchmark
                cmd = f"""docker run \\
                    --rm \\
                    --cpuset-cpus='0-{w}' \\
                    -v '{DATA}/{dp}:/data' \\
                    -v '{os.getcwd()}:/payload' \\
                    -w /payload \\
                    --user root \\
                    umbradb/umbra:25.07.1 \\
                    /usr/local/bin/umbra-sql -createdb '/payload/test.db' '/payload/{dl}.sql'"""
                
                # Clear system caches for consistent benchmarking
                clear_caches()
                
                # Run benchmark with timeout and capture execution time
                time_cmd = f"/usr/bin/time -f 'LinuxRT: %e' timeout {tout} dlbench run \"{cmd}\" \"{tag}\""
                exit_code, stdout, stderr = run_command(time_cmd, timeout_sec + 10)
                
                # Write stderr to info file
                with open(f"{tag}.info", 'w') as f:
                    f.write(stderr)
                
                # Determine benchmark result status
                status = get_status_from_exit_code(exit_code)
                
                # Extract LinuxRT from stderr
                linux_rt = ""
                if stderr:
                    rt_match = re.search(r'LinuxRT: ([0-9.]+)', stderr)
                    if rt_match:
                        linux_rt = rt_match.group(1)
                
                # Extract benchmark metrics
                correctness_output = extract_metric(key, f"{tag}*.out")
                dlbench_runtime = get_last_field(f"{tag}*.log")
                load_time = extract_metric("load_time", f"{tag}*.out")
                
                # Write results to info file
                with open(f"{tag}.info", 'a') as f:
                    f.write(f"Status: {status}\n")
                    f.write(f"DLOut: {correctness_output}\n")
                    f.write(f"DLBenchRT: {dlbench_runtime}\n")
                    f.write(f"load_time: {load_time}\n")
                
                # Write corresponding JSON file
                result_data = {
                    "status": status,
                    "runtime": linux_rt,
                    "correctness_output": correctness_output,
                    "dlbench_runtime": dlbench_runtime,
                    "load_time": load_time
                }
                
                with open(f"{tag}.json", 'w') as f:
                    json.dump(result_data, f, indent=2)

if __name__ == "__main__":
    main()