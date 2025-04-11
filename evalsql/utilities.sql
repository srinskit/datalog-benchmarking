-- DROP TABLE runs;
-- CREATE TABLE
-- 	runs (
-- 		program TEXT,
-- 		dataset TEXT,
-- 		engine TEXT,
-- 		workers INTEGER,
-- 		status TEXT,
-- 		runtime REAL,
-- 		output TEXT,
-- 		dlbench_runtime REAL,
-- 		cmpl_time REAL,
-- 		folder TEXT,
-- 		UNIQUE (program, dataset, engine, workers, folder)
-- 	);
-- SELECT
-- 	COUNT(*)
-- FROM
-- 	runs;
-- -- .mode csv;
-- -- .import data.csv runs;

-- SELECT
-- 	COUNT(*)
-- FROM
-- 	runs;
-- UPDATE runs
-- SET
-- 	program = 'doop'
-- WHERE
-- 	program IN ('batik', 'biojava', 'eclipse', 'xalan', 'zxing');

-- SELECT
-- 	program,
-- 	dataset,
-- 	runtime,
-- 	workers,
-- 	(
-- 		CASE
-- 			WHEN program <> 'doop' THEN (
-- 				'dlbench plot --logs dlbench-results/' || folder || '/' || program || '_' || dataset || '_' || workers || '*' || '.log'
-- 			)
-- 			ELSE (
-- 				'dlbench plot --logs dlbench-results/' || folder || '/' || dataset || '_' || dataset || '_' || workers || '*' || '.log'
-- 			)
-- 		END
-- 	) AS logs
-- FROMw
-- 	runs;


-- SELECT
-- 	program,
-- 	dataset,
-- 	workers,
-- 	count(DISTINCT folder)
-- FROM
-- (
-- SELECT
-- 	program,
-- 	dataset,
-- 	workers,
-- 	engine,
-- 	max(folder) as max_folder,
-- 	min(folder) as min_folder
-- FROM
-- 	runs
-- WHERE output <> ''
-- GROUP BY program, dataset, workers, engine
-- ) GROUP BY program, dataset, workers;

-- SELECT
-- 	min(folder) as min_folder
-- FROM
-- 	runs
-- WHERE output <> '';

	-- (
	-- 	CASE
	-- 		WHEN program <> 'doop' THEN (
	-- 			'dlbench plot --logs dlbench-results/' || folder || '/' || program || '_' || dataset || '_' || workers || '*' || '.log'
	-- 		)
	-- 		ELSE (
	-- 			'dlbench plot --logs dlbench-results/' || folder || '/' || dataset || '_' || dataset || '_' || workers || '*' || '.log'
	-- 		)
	-- 	END
	-- ) AS logs

select * from runs
order by folder desc;
