.load /home/srin/projects/cloudlab-auto/regex0.so
-- CREATE TEMP TABLE
-- 	runtimes AS
-- SELECT
-- 	base_program,
-- 	base_engine,
-- 	program,
-- 	dataset,
-- 	workers,
-- 	engine,
-- 	(
-- 		CASE
-- 			WHEN cmp > 0 THEN runtime
-- 			WHEN oom > 0 THEN 'OOM'
-- 			WHEN tout > 0 THEN 'TOUT'
-- 			ELSE 'DNF'
-- 		END
-- 	) AS display,
-- 	cmpl_time
-- FROM
	-- (
		SELECT
			-- MIN(program) AS base_program,
			-- MIN(engine) AS base_engine,
			regex_replace ('-(opt|sip)$', program, '') AS program,
			(
				CASE
					WHEN program REGEXP '-(opt|sip)$' THEN engine || '-opt'
					ELSE engine
				END
			) AS engine,
			dataset,
			workers,
			COUNT(
				CASE
					WHEN status = 'CMP'
					AND output <> '' THEN 1
				END
			) AS cmp,
			COUNT(
				CASE
					WHEN status = 'OOM' THEN 1
				END
			) AS oom,
			COUNT(
				CASE
					WHEN status = 'TOUT' THEN 1
				END
			) AS tout,
			MIN(
				CASE
					WHEN status = 'CMP'
					AND output <> '' THEN runtime
				END
			) AS runtime,
			ROUND(MIN(cmpl_time), 2) AS cmpl_time
		FROM
			runs
		GROUP BY
			program,
			dataset,
			workers,
			engine
		HAVING
			(
				(program LIKE 'galen%')
				OR (
					program LIKE 'ddisasm%'
					AND dataset = 'z3'
				)
				OR (
					program LIKE 'doop%'
					AND dataset = 'batik'
				)
			)
			AND workers = '64';
	-- );

-- SELECT
-- 	*
-- FROM
-- 	runtimes;

SELECT
	runtimes.program,
	runtimes.dataset,
	runtimes.workers,
	MAX(
		CASE
			WHEN runtimes.engine = 'flowlog' THEN runtimes.display
		END
	) AS flowlog,
	MAX(
		CASE
			WHEN runtimes.engine = 'flowlog-opt' THEN runtimes.display
		END
	) AS flowlog_opt,
	MAX(
		CASE
			WHEN runtimes.engine = 'souffle-cmpl' THEN runtimes.display
		END
	) AS souffle_c,
	MAX(
		CASE
			WHEN runtimes.engine = 'souffle-intptr' THEN runtimes.display
		END
	) AS souffle_i,
	MAX(
		CASE
			WHEN runtimes.engine = 'flowlog' THEN MIN(256, ROUND(runs.peak_mem / 1073741824.0, 2))
		END
	) AS flowlog_peak_mem,
	MAX(
		CASE
			WHEN runtimes.engine = 'souffle-cmpl' THEN MIN(256, ROUND(runs.peak_mem / 1073741824.0, 2))
		END
	) AS souffle_c_peak_mem,
	MAX(
		CASE
			WHEN runtimes.engine = 'souffle-intptr' THEN MIN(256, ROUND(runs.peak_mem / 1073741824.0, 2))
		END
	) AS souffle_i_peak_mem
FROM
	runtimes
	LEFT JOIN runs ON (
		(
			runtimes.display = runs.runtime
			OR runtimes.display = runs.status
		)
		AND runtimes.base_program = runs.program
		AND runtimes.dataset = runs.dataset
		AND runtimes.base_engine = runs.engine
		AND runtimes.workers = runs.workers
	)
GROUP BY
	runtimes.program,
	runtimes.dataset,
	runtimes.workers
ORDER BY
	runtimes.program,
	runtimes.dataset,
	runtimes.workers;