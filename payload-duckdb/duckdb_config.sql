-- DuckDB-specific configuration for performance
-- Run this before the main setup for DuckDB

PRAGMA threads=4;
PRAGMA memory_limit='16GB';
PRAGMA enable_progress_bar=true;
