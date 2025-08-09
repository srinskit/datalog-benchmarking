-- Same Generation implementation in SQL
-- Based on sg.dl Datalog program
-- Compatible with both DuckDB and Umbra

CREATE TEMPORARY TABLE timing_log (start_time TIMESTAMP);
INSERT INTO timing_log VALUES (CURRENT_TIMESTAMP);

CREATE TABLE arc (
    src INTEGER,
    dest INTEGER
);

COPY arc FROM '/data/Arc.csv' (FORMAT CSV, HEADER false);

SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) AS load_time
FROM timing_log;

-- Find nodes at same generation level in tree structure
WITH RECURSIVE sg(src, dest) AS (
    -- Base case: siblings (same parent, different children)
    SELECT a1.dest, a2.dest
    FROM arc a1 JOIN arc a2 ON a1.src = a2.src
    WHERE a1.dest != a2.dest
    UNION
    -- Recursive case: propagate same generation through paths
    SELECT a1.dest, a2.dest
    FROM arc a1 JOIN sg ON a1.src = sg.src JOIN arc a2 ON sg.dest = a2.src
)
SELECT COUNT(*) AS Sg FROM sg;

DROP TABLE timing_log;