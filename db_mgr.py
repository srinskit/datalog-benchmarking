#!/usr/bin/env python3

import sqlite3
import json
import os
import argparse
import re
import logging
from pathlib import Path
import sys
from collections import defaultdict
import statistics

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


class BenchmarkDB:
    def __init__(self, db_path):
        self.db_path = db_path

    def create_database(self):
        """Create SQLite database with benchmark results table"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS benchmark_results (
                program TEXT NOT NULL,
                plan_set INTEGER NOT NULL,
                dataset TEXT NOT NULL,
                threads INTEGER NOT NULL,
                engine TEXT NOT NULL,
                status TEXT NOT NULL,
                correctness_output INTEGER,
                runtime REAL,
                compile_time REAL,
                load_time REAL,
                profiler_load_time REAL,
                result_folder TEXT NOT NULL,
                PRIMARY KEY (program, plan_set, dataset, threads, engine, result_folder)
            )
        """
        )

        conn.commit()
        conn.close()
        logger.info(f"Database created at {self.db_path}")

    def drop_database(self):
        """Drop the benchmark results table"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database {self.db_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS benchmark_results")
        conn.commit()
        conn.close()
        logger.info(f"Table dropped from {self.db_path}")

    def parse_filename(self, filename):
        """Parse benchmark result filename to extract metadata"""
        # Pattern: {program}_{plan_set}_{dataset}_{threads}_{engine}.json
        pattern = r'^(.+?)_(\d+)_(.+?)_(\d+)_(.+?)\.json$'
        match = re.match(pattern, filename)

        if match:
            program, plan_set, dataset, threads, engine = match.groups()
            return program, int(plan_set), dataset, int(threads), engine
        return None, None, None, None, None

    def load_folder(self, folder_path):
        """Load benchmark data from folder containing JSON files"""
        folder_path = Path(folder_path)
        if not folder_path.exists():
            logger.error(f"Folder {folder_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        loaded_count = 0
        skipped_count = 0
        duplicate_count = 0

        for json_file in folder_path.glob("*.json"):
            if json_file.name == "targets.json":
                continue

            program, plan_set, dataset, threads, engine = self.parse_filename(
                json_file.name
            )
            if not program:
                logger.warning(f"Skipping {json_file.name}: couldn't parse filename")
                skipped_count += 1
                continue

            try:
                with open(json_file, "r") as f:
                    data = json.load(f)

                profiler_load_time = data.get("profiler_load_time")

                cursor.execute(
                    """
                    INSERT OR IGNORE INTO benchmark_results 
                    (program, plan_set, dataset, threads, engine, status, correctness_output, 
                     runtime, compile_time, load_time, profiler_load_time, result_folder)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                    (
                        program,
                        plan_set,
                        dataset,
                        threads,
                        engine,
                        data.get("status"),
                        data.get("correctness_output"),
                        data.get("runtime"),
                        data.get("compile_time"),
                        data.get("load_time"),
                        profiler_load_time,
                        folder_path.name,
                    ),
                )

                if cursor.rowcount == 0:
                    duplicate_count += 1
                else:
                    loaded_count += 1

            except (json.JSONDecodeError, KeyError) as e:
                logger.error(f"Error processing {json_file.name}: {e}")
                skipped_count += 1

        conn.commit()
        conn.close()
        logger.info(
            f"Loaded {loaded_count} records, skipped {skipped_count} files, found {duplicate_count} duplicates from {folder_path}"
        )

    def show_data(self):
        """Display all data in the database table with pretty formatting"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database {self.db_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT program, plan_set, dataset, threads, engine, status, 
                   correctness_output, runtime, compile_time, load_time, profiler_load_time, result_folder
            FROM benchmark_results 
            ORDER BY result_folder, program, dataset, plan_set, threads, engine
        """
        )

        rows = cursor.fetchall()
        conn.close()

        if not rows:
            logger.info("No data found in database")
            return

        # Print header
        logger.info(
            f"{'Program':<12} {'Plan':<4} {'Dataset':<10} {'Threads':<7} {'Engine':<15} {'Status':<6} {'Correct':<8} {'Runtime':<8} {'Compile':<8} {'Load':<8} {'ProfLoad':<8} {'Folder':<20}"
        )
        logger.info("-" * 128)

        # Print data rows
        for row in rows:
            (
                program,
                plan_set,
                dataset,
                threads,
                engine,
                status,
                correct,
                runtime,
                compile_time,
                load_time,
                profiler_load_time,
                folder,
            ) = row
            correct_str = str(correct) if correct is not None else "NULL"
            runtime_str = f"{runtime:.2f}" if runtime is not None else "NULL"
            compile_str = f"{compile_time:.2f}" if compile_time is not None else "NULL"
            load_str = f"{load_time:.2f}" if load_time is not None else "NULL"
            prof_load_str = (
                f"{profiler_load_time:.2f}"
                if profiler_load_time is not None
                else "NULL"
            )

            logger.info(
                f"{program:<12} {plan_set:<4} {dataset:<10} {threads:<7} {engine:<15} {status:<6} {correct_str:<8} {runtime_str:<8} {compile_str:<8} {load_str:<8} {prof_load_str:<8} {folder:<20}"
            )

    def verify_correctness(self):
        """Verify that all CMP records for the same program-dataset have consistent correctness values"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database {self.db_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT program, dataset, correctness_output, COUNT(*) as count
            FROM benchmark_results 
            WHERE status = 'CMP'
            GROUP BY program, dataset, correctness_output
            ORDER BY program, dataset
        """
        )

        results = cursor.fetchall()

        # Group by program-dataset and check for multiple correctness values
        violations = {}
        for program, dataset, correctness, count in results:
            key = (program, dataset)
            if key not in violations:
                violations[key] = []
            violations[key].append((correctness, count))

        found_violations = False
        for (program, dataset), correctness_list in violations.items():
            if len(correctness_list) > 1:
                found_violations = True
                correctness_info = ", ".join(
                    [
                        f"{correctness}({count})"
                        for correctness, count in correctness_list
                    ]
                )
                logger.error(f"VIOLATION: {program} on {dataset} - {correctness_info}")

        # Find any runs where the status is TOUT but runtime is not 900.0
        cursor.execute(
            """
            SELECT result_folder, program, dataset, runtime
            FROM benchmark_results
            WHERE status = 'TOUT' AND runtime < 800.0
        """
        )

        results = cursor.fetchall()

        if len(results) > 0:
            found_violations = True
            for result_folder, program, dataset, runtime in results:
                logger.error(
                    f"TOUT VIOLATION: {program} on {dataset} in {result_folder} - runtime {runtime} is not 900.0"
                )

        if not found_violations:
            logger.info("No correctness violations found.")

        conn.close()

    def summary(self):
        """Print median runtime summary for each program, dataset, engine, and worker count"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database {self.db_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT program, dataset, engine, threads, runtime, status, plan_set
            FROM benchmark_results 
            WHERE status = 'CMP' or status = 'TOUT'
            ORDER BY program, dataset, engine, threads
        """
        )

        rows = cursor.fetchall()
        conn.close()

        if not rows:
            logger.info("No completed runtime data found")
            return

        # Group by (program, dataset, engine, threads) and organize runtimes and plan sets
        _plans = defaultdict(set)
        _samples = defaultdict(int)
        program_runtimes = defaultdict(lambda: defaultdict(list))
        for program, dataset, engine, threads, runtime, status, plan_set in rows:
            # Assert runtime is never null for CMP / TOUT status
            assert (
                runtime is not None
            ), f"Runtime is null for CMP/TOUT record: {program}, {dataset}, {engine}, {threads}"
            key = (program, dataset, engine, threads)
            adjusted_runtime = runtime if status == "CMP" else sys.maxsize
            program_runtimes[key][plan_set].append(adjusted_runtime)
            
            # Collect sample size information
            _plans[key].add(plan_set)
            _samples[key] += 1

        # Calculate median runtimes for each plan set
        agg_program_runtimes = defaultdict(list)

        for key, plan_runtimes in program_runtimes.items():
            for plan_set, runtimes in plan_runtimes.items():
                assert (
                    len(runtimes) > 0
                ), f"No runtimes for plan set {plan_set} in {key}"
                agg_program_runtimes[key].append(statistics.median(runtimes))

        # Calculate median runtime for each program
        reduced_program_runtimes = defaultdict(tuple)
        for key, runtimes in agg_program_runtimes.items():
            median_runtime = statistics.median(runtimes)
            reduced_program_runtimes[key] = (
                median_runtime if median_runtime < 900 else -2,
                _samples[key],
                len(_plans[key]),
            )

        # Print results
        logger.info(
            f"{'Program':<12} {'Dataset':<15} {'Engine':<15} {'Workers':<7} {'M Runtime':<15} {'Sample Size':<15} {'Plan Count':<7}"
        )
        logger.info("-" * 100)

        for (program, dataset, engine, threads), (
            median_runtime,
            sample_size,
            plan_count,
        ) in reduced_program_runtimes.items():
            logger.info(
                f"{program:<12} {dataset:<15} {engine:<15} {threads:<7} {median_runtime:<15.2f} {sample_size:<15} {plan_count:<7}"
            )

    def query(self, sql):
        """Execute custom SQL query and display results"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database {self.db_path} does not exist")
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            cursor.execute(sql)
            rows = cursor.fetchall()

            if rows:
                # Get column names
                columns = [description[0] for description in cursor.description]

                # Print header
                header = " | ".join(f"{col:<15}" for col in columns)
                logger.info(header)
                logger.info("-" * len(header))

                # Print rows
                for row in rows:
                    formatted_row = " | ".join(
                        f"{str(val) if val is not None else 'NULL':<15}" for val in row
                    )
                    logger.info(formatted_row)
            else:
                logger.info("No results returned")

        except sqlite3.Error as e:
            logger.error(f"SQL error: {e}")
        finally:
            conn.close()


def main():
    parser = argparse.ArgumentParser(description="Benchmark Results Database Manager")
    parser.add_argument("database", help="Path to SQLite database file")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Create / drop database command
    subparsers.add_parser("create", help="Create SQLite database")
    subparsers.add_parser("drop", help="Drop benchmark results table")

    # Load data command
    load_parser = subparsers.add_parser(
        "load", help="Load benchmark data from folder(s)"
    )
    load_parser.add_argument(
        "folders",
        nargs="+",
        help="Path(s) or bash pattern(s) to folder(s) containing JSON result files",
    )

    # Load latest data command
    load_latest_parser = subparsers.add_parser(
        "load-latest", help="Load benchmark data from latest subfolder"
    )
    load_latest_parser.add_argument(
        "folder", help="Path to parent folder containing subfolders"
    )

    # Show data command
    subparsers.add_parser("show", help="Display all data in the database")

    # Verify correctness command
    subparsers.add_parser(
        "verify", help="Verify correctness consistency across results"
    )

    # Summary command
    subparsers.add_parser("summary", help="Print median runtime summary")

    # Query command
    query_parser = subparsers.add_parser("query", help="Execute custom SQL query")
    query_parser.add_argument("sql", help="SQL query to execute")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    db = BenchmarkDB(args.database)

    if args.command == "create":
        db.create_database()
    elif args.command == "drop":
        db.drop_database()
    elif args.command == "load":
        if not os.path.exists(args.database):
            logger.error(f"Database {args.database} does not exist. Create it first.")
            return
        import glob

        folders = []
        for pattern in args.folders:
            folders.extend([f for f in glob.glob(pattern) if os.path.isdir(f)])
        if not folders:
            logger.error("No valid folders found for the given patterns.")
            return
        for folder in folders:
            db.load_folder(folder)
    elif args.command == "load-latest":
        if not os.path.exists(args.database):
            logger.error(f"Database {args.database} does not exist. Create it first.")
            return

        # Find latest subfolder
        if not os.path.exists(args.folder):
            logger.error(f"Folder {args.folder} does not exist")
            return

        subfolders = [
            d
            for d in os.listdir(args.folder)
            if os.path.isdir(os.path.join(args.folder, d))
        ]

        if not subfolders:
            logger.error(f"No subfolders found in {args.folder}")
            return

        latest_folder = max(
            subfolders, key=lambda d: os.path.getctime(os.path.join(args.folder, d))
        )
        latest_path = os.path.join(args.folder, latest_folder)

        logger.info(f"Loading from latest subfolder: {latest_path}")
        db.load_folder(latest_path)
    elif args.command == "show":
        db.show_data()
    elif args.command == "verify":
        db.verify_correctness()
    elif args.command == "summary":
        db.summary()
    elif args.command == "query":
        db.query(args.sql)


if __name__ == "__main__":
    main()
