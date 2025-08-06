#!/usr/bin/env python3
import os
import csv
import re
import json
import argparse

def get_souffle_loadtime(json_file):
    """Extract the loadtime attribute for all relations from a JSON file."""
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        # Navigate to the relations
        relations = data["root"]["program"]["relation"]
        total_loadtime = 0
        
        # Process each relation that has a loadtime attribute
        for relation_name, relation_data in relations.items():
            if "loadtime" in relation_data:
                loadtime = relation_data["loadtime"]
                start_time = loadtime["start"]
                end_time = loadtime["end"]
                duration = (end_time - start_time) / 1000000  # Convert to seconds
                total_loadtime += duration
        
        return total_loadtime
        
    except (KeyError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error extracting loadtime: {e}")

def get_flowlog_loadtime(out_file_path):
    """Find the timestamp of the last 'Data loaded for...' line in the .out file."""
    last_timestamp = None
    # Pattern for both seconds and milliseconds
    pattern = re.compile(r"(\d+\.\d+)(ms|s):\s*Data loaded for")

    try:
        with open(out_file_path, "r") as f:
            for line in f:
                match = pattern.search(line)
                if match:
                    value = float(match.group(1))
                    unit = match.group(2)
                    # Convert to seconds if in milliseconds
                    if unit == "ms":
                        value = value / 1000.0
                    last_timestamp = value
    except FileNotFoundError:
        return None

    return last_timestamp


def find_rate_drop_time(rows, threshold):
    """Find the earliest time when IO rate drops below the threshold, starting from the latest time."""
    # Assert that rows exist
    assert rows and len(rows) > 0, "No rows provided for analysis"
    
    # Calculate all rates
    rates = []
    prev_time = 0.0
    prev_io = 0

    for row in rows:
        time = float(row["Time"])
        io_reads = int(row["IO Reads"])

        time_diff_ms = (time - prev_time) * 1000
        io_rate_ms = (io_reads - prev_io) / time_diff_ms
        rates.append((time, io_rate_ms))

        prev_time = time
        prev_io = io_reads

    # Simple assertion that we have rates for each row
    assert len(rates) == len(rows), "Rates and rows count mismatch"

    prev_time = None

    # Start from the end (latest time) and go backwards
    for i in range(len(rates) - 1, -1, -1):
        time, rate = rates[i]
        if rate > threshold:
            return time
        prev_time = time

    return None

def read_log_files(directory, threshold):
    """Read all .log files in the specified directory and analyze IO rates."""
    # Get all .log files in the directory and sort them by name
    log_files = sorted([f for f in os.listdir(directory) if f.endswith(".log")])

    for log_file in log_files:
        file_path = os.path.join(directory, log_file)
        data_loaded_timestamp = None
        
        source_file = "out"
        
        # Handle different file types based on name
        if "flowlog" in log_file:
            # For flowlog, use .out file
            out_file = log_file.replace(".log", ".out")
            out_file_path = os.path.join(directory, out_file)
            data_loaded_timestamp = get_flowlog_loadtime(out_file_path)
            source_file = "out"
        elif "souffle" in log_file:
            # For souffle, use .profile file
            profile_file = log_file.replace(".log", ".profile")
            profile_file_path = os.path.join(directory, profile_file)
            data_loaded_timestamp = get_souffle_loadtime(profile_file_path)
            source_file = "profile"

        print(f"\nFile: {log_file}")
        if data_loaded_timestamp is not None:
            print(f"IO end (.{source_file}): {data_loaded_timestamp:.2f}s")
        else:
            print(f"IO end (.{source_file}): N/A")

        # Read the log file data
        with open(file_path, "r") as f:
            csv_reader = csv.DictReader(f)
            rows = list(csv_reader)

        # Find when IO rate drops below threshold
        drop_time = find_rate_drop_time(rows, threshold)
        if drop_time is not None:
            print(f"IO end (.log): {drop_time:.2f}s")
        else:
            print(f"IO rate never dropped below {threshold} bytes/ms")
            
        # Print the last time value in the CSV file
        last_time = float(rows[-1]["Time"])
        print(f"EX end (.log): {last_time:.2f}s")
            
        if data_loaded_timestamp is not None and drop_time is not None:
            error = (drop_time - data_loaded_timestamp) * 100.0 / last_time
            print(f"IO calc error: {error:.2f}%")
        
        io_cont = 100.0 * drop_time / last_time
        print(f"IO contribution: {io_cont:.2f}%")
    


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze IO rates in log files.")
    parser.add_argument("directory", type=str, help="Directory containing log files")
    parser.add_argument(
        "threshold", type=int, help="Threshold for IO rate drop detection (bytes/ms)"
    )

    args = parser.parse_args()
    read_log_files(args.directory, args.threshold)
