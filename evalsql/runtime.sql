CREATE TEMP TABLE
	runtimes AS
SELECT
	program,
	dataset,
	workers,
	engine,
	(
		CASE
			WHEN cmp > 0 THEN runtime
			WHEN oom > 0 THEN 'OOM'
			WHEN tout > 0 THEN 'TOUT'
			ELSE 'DNF'
		END
	) AS display,
	cmpl_time
FROM
	(
		SELECT
			program,
			dataset,
			workers,
			engine,
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
	);

-- Transform engine attr values to columns
SELECT
	program,
	dataset,
	workers,
	MAX(
		CASE
			WHEN engine = 'flowlog' THEN display
		END
	) AS flowlog,
	MAX(
		CASE
			WHEN engine = 'souffle-cmpl' THEN display
		END
	) AS souffle_c,
	MAX(
		CASE
			WHEN engine = 'souffle-intptr' THEN display
		END
	) AS souffle_i,
	MAX(
		CASE
			WHEN engine = 'recstep' THEN display
		END
	) AS recstep,
	MAX(
		CASE
			WHEN engine = 'ddlog' THEN display
		END
	) AS ddlog,
	MAX(
		CASE
			WHEN engine = 'souffle-cmpl' THEN cmpl_time
		END
	) AS souffle_cmpl_time,
	MAX(
		CASE
			WHEN engine = 'ddlog' THEN cmpl_time
		END
	) AS ddlog_cmpl_time
FROM
	runtimes
GROUP BY
	program,
	dataset,
	workers
HAVING
	INSTR(program, '-') = 0
	AND workers IN (4, 64)
ORDER BY
	program,
	dataset,
	workers;

-- Print commands to copy best stats into a folder
SELECT
	(
		'cp dlbench-results/' || runs.folder || '/' || runtimes.program || '_' || runtimes.dataset || '_' || runtimes.workers || '_' || runtimes.engine || '*' || ' compiled_results/'
	) AS command
FROM
	runtimes
	LEFT JOIN runs ON (
		(
			runtimes.display = runs.runtime
			OR runtimes.display = runs.status
		)
		AND runtimes.program = runs.program
		AND runtimes.dataset = runs.dataset
		AND runtimes.engine = runs.engine
		AND runtimes.workers = runs.workers
	)
WHERE
	INSTR(runtimes.program, '-') = 0
	AND runtimes.workers IN (4, 64)
	AND runtimes.display <> 'DNF';