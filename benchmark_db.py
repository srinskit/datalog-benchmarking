#!/usr/bin/env python3

import sqlite3
import json
import os
import argparse
import re
from pathlib import Path

class BenchmarkDB:
    def __init__(self, db_path):
        self.db_path = db_path
        
    def create_database(self):
        """Create SQLite database with benchmark results table"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
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
                result_folder TEXT NOT NULL,
                PRIMARY KEY (program, plan_set, dataset, threads, engine, result_folder)
            )
        ''')
        
        conn.commit()
        conn.close()
        print(f"Database created at {self.db_path}")
    
    def drop_database(self):
        """Drop the benchmark results table"""
        if not os.path.exists(self.db_path):
            print(f"Error: Database {self.db_path} does not exist")
            return
            
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('DROP TABLE IF EXISTS benchmark_results')
        conn.commit()
        conn.close()
        print(f"Table dropped from {self.db_path}")
    
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
            print(f"Error: Folder {folder_path} does not exist")
            return
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        loaded_count = 0
        skipped_count = 0
        
        for json_file in folder_path.glob("*.json"):
            if json_file.name == "targets.json":
                continue
                
            program, plan_set, dataset, threads, engine = self.parse_filename(json_file.name)
            if not program:
                print(f"Skipping {json_file.name}: couldn't parse filename")
                skipped_count += 1
                continue
            
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                
                cursor.execute('''
                    INSERT OR REPLACE INTO benchmark_results 
                    (program, plan_set, dataset, threads, engine, status, correctness_output, 
                     runtime, compile_time, load_time, result_folder)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    program,
                    plan_set,
                    dataset,
                    threads,
                    engine,
                    data.get('status'),
                    data.get('correctness_output'),
                    data.get('runtime'),
                    data.get('compile_time'),
                    data.get('load_time'),
                    folder_path.name
                ))
                loaded_count += 1
                
            except (json.JSONDecodeError, KeyError) as e:
                print(f"Error processing {json_file.name}: {e}")
                skipped_count += 1
        
        conn.commit()
        conn.close()
        print(f"Loaded {loaded_count} records, skipped {skipped_count} files from {folder_path}")
    
    def show_data(self, sort_by):
        """Display all data in the database table with pretty formatting"""
        if not os.path.exists(self.db_path):
            print(f"Error: Database {self.db_path} does not exist")
            return
            
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        if sort_by == 'folder':
            order_clause = 'ORDER BY result_folder, program, plan_set, dataset, threads, engine'
        else:  # sort_by == 'program'
            order_clause = 'ORDER BY program, plan_set, dataset, threads, engine, result_folder'
            
        cursor.execute(f'''
            SELECT program, plan_set, dataset, threads, engine, status, 
                   correctness_output, runtime, compile_time, load_time, result_folder
            FROM benchmark_results {order_clause}
        ''')
        
        rows = cursor.fetchall()
        conn.close()
        
        if not rows:
            print("No data found in database")
            return
            
        # Print header
        print(f"{'Program':<12} {'Plan':<4} {'Dataset':<10} {'Threads':<7} {'Engine':<15} {'Status':<6} {'Correct':<8} {'Runtime':<8} {'Compile':<8} {'Load':<8} {'Folder':<20}")
        print("-" * 120)
        
        # Print data rows
        for row in rows:
            program, plan_set, dataset, threads, engine, status, correct, runtime, compile_time, load_time, folder = row
            correct_str = str(correct) if correct is not None else 'NULL'
            runtime_str = f"{runtime:.2f}" if runtime is not None else 'NULL'
            compile_str = f"{compile_time:.2f}" if compile_time is not None else 'NULL'
            load_str = f"{load_time:.2f}" if load_time is not None else 'NULL'
            
            print(f"{program:<12} {plan_set:<4} {dataset:<10} {threads:<7} {engine:<15} {status:<6} {correct_str:<8} {runtime_str:<8} {compile_str:<8} {load_str:<8} {folder:<20}")

def main():
    parser = argparse.ArgumentParser(description='Benchmark Results Database Manager')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Create database command
    create_parser = subparsers.add_parser('create', help='Create SQLite database')
    create_parser.add_argument('database', help='Path to SQLite database file')
    
    # Drop database command
    drop_parser = subparsers.add_parser('drop', help='Drop benchmark results table')
    drop_parser.add_argument('database', help='Path to SQLite database file')
    
    # Load data command
    load_parser = subparsers.add_parser('load', help='Load benchmark data from folder')
    load_parser.add_argument('database', help='Path to SQLite database file')
    load_parser.add_argument('folder', help='Path to folder containing JSON result files')
    
    # Show data command
    show_parser = subparsers.add_parser('show', help='Display all data in the database')
    show_parser.add_argument('database', help='Path to SQLite database file')
    show_parser.add_argument('--sort-by', choices=['folder', 'program'], default='program', help='Primary sort column (default: program)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    db = BenchmarkDB(args.database)
    
    if args.command == 'create':
        db.create_database()
    elif args.command == 'drop':
        db.drop_database()
    elif args.command == 'load':
        if not os.path.exists(args.database):
            print(f"Error: Database {args.database} does not exist. Create it first.")
            return
        db.load_folder(args.folder)
    elif args.command == 'show':
        db.show_data(args.sort_by)

if __name__ == '__main__':
    main()