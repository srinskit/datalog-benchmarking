-- Connected Components implementation in SQL
-- Based on cc.dl Datalog program
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

-- Find connected components by propagating minimum node ID
WITH RECURSIVE cc3(x, min_x) AS (
    -- Base case: each node starts with global minimum
    SELECT x, MIN(x) OVER () FROM arc
    UNION
    -- Recursive case: propagate minimum through edges
    SELECT arc.y, MIN(cc3.min_x) OVER ()
    FROM cc3 JOIN arc ON cc3.x = arc.x
),
-- Find minimum component ID for each node
cc2(x, min_y) AS (
    SELECT x, MIN(min_x) FROM cc3 GROUP BY x
)
-- Count distinct component IDs
SELECT COUNT(DISTINCT min_y) AS CC FROM cc2;

DROP TABLE timing_log;