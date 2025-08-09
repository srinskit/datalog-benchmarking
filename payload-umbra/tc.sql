-- Transitive Closure implementation in SQL
-- Based on tc.dl Datalog program
-- Compatible with both DuckDB and Umbra

CREATE TEMPORARY TABLE timing_log (start_time TIMESTAMP);
INSERT INTO timing_log VALUES (CURRENT_TIMESTAMP);

CREATE TABLE arc (
    x INTEGER,
    y INTEGER
);

COPY arc FROM '/data/Arc.csv' (FORMAT CSV, HEADER false);

SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) AS load_time
FROM timing_log;

-- Compute transitive closure of all arc relationships
WITH RECURSIVE tc(x, y) AS (
    -- Base case: direct arcs
    SELECT x, y FROM arc
    UNION
    -- Recursive case: chain arcs together
    SELECT tc.x, arc.y
    FROM tc JOIN arc ON tc.y = arc.x
)
SELECT COUNT(*) AS Tc FROM tc;

DROP TABLE timing_log;