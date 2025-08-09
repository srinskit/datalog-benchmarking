-- Reachability problem implementation in SQL
-- Based on reach.dl Datalog program
-- Compatible with both DuckDB and Umbra

CREATE TEMPORARY TABLE timing_log (start_time TIMESTAMP);
INSERT INTO timing_log VALUES (CURRENT_TIMESTAMP);

CREATE TABLE arc (
    x INTEGER,
    y INTEGER
);

CREATE TABLE source (
    id INTEGER
);

COPY arc FROM '/data/Arc.csv' (FORMAT CSV, HEADER false);
COPY source FROM '/data/Source.csv' (FORMAT CSV, HEADER false);

SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) AS load_time
FROM timing_log;

-- Compute transitive closure starting from source nodes
WITH RECURSIVE reach(id) AS (
    -- Base case: start with source nodes
    SELECT id FROM source
    UNION
    -- Recursive case: follow arcs from reached nodes
    SELECT arc.y
    FROM reach JOIN arc ON reach.id = arc.x
)
SELECT COUNT(*) AS Reach FROM reach;

DROP TABLE timing_log;