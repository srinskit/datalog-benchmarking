-- Setup: Create tables and load data for bipartite graph detection
-- Based on bipartite.dl Datalog program
-- Compatible with both DuckDB and Umbra

-- Create arc table (edges in the graph)
CREATE TABLE arc (
    y INTEGER,
    x INTEGER
);

-- Create source table (starting nodes)
CREATE TABLE source (
    x INTEGER
);

-- Load data from CSV files
-- Note: Both DuckDB and Umbra support this COPY syntax
COPY arc FROM '/data/Arc.csv' (FORMAT CSV, HEADER false);
COPY source FROM '/data/Source.csv' (FORMAT CSV, HEADER false);

WITH RECURSIVE
    coloring(x, color) AS (
        -- Base case: Start from source nodes, color 0
        SELECT x, 0 FROM source
        UNION
        -- Recursive case: Propagate to neighbors with opposite color
        SELECT neighbor, 1 - color
        FROM (
            SELECT arc.y AS neighbor, coloring.color
            FROM coloring JOIN arc ON arc.x = coloring.x
            UNION ALL
            SELECT arc.x AS neighbor, coloring.color
            FROM coloring JOIN arc ON arc.y = coloring.x
        ) AS derived
    )
SELECT
    COUNT(DISTINCT x) FILTER (WHERE color = 0) AS Zero
    -- COUNT(DISTINCT x) FILTER (WHERE color = 1) AS one_count,
    -- -- Count the intersection of the two sets
    -- COUNT(DISTINCT x) FILTER (WHERE color = 0 AND x IN (SELECT x FROM coloring WHERE color = 1)) AS intersection_count
FROM coloring;
