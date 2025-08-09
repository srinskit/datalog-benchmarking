-- Context Sensitive Data Analysis implementation in SQL
-- Based on csda.dl Datalog program
-- Compatible with both DuckDB and Umbra

CREATE TEMPORARY TABLE timing_log (start_time TIMESTAMP);
INSERT INTO timing_log VALUES (CURRENT_TIMESTAMP);

CREATE TABLE nulledge (
    x INTEGER,
    y INTEGER
);

CREATE TABLE edge (
    x INTEGER,
    y INTEGER
);

COPY nulledge FROM '/data/NullEdge.csv' (FORMAT CSV, HEADER false);
COPY edge FROM '/data/Edge.csv' (FORMAT CSV, HEADER false);

SELECT EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) AS load_time
FROM timing_log;

-- Propagate null values through graph edges
WITH RECURSIVE nullnode(x, y) AS (
    -- Base case: direct null edges
    SELECT x, y FROM nulledge
    UNION
    -- Recursive case: propagate nulls through regular edges
    SELECT nullnode.x, edge.y
    FROM nullnode JOIN edge ON nullnode.y = edge.x
)
SELECT COUNT(*) AS NullNode FROM nullnode;

DROP TABLE timing_log;