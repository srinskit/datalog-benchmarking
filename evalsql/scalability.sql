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
	(
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
					ROUND(
						MIN(
							CASE
								WHEN status = 'CMP'
								AND output <> '' THEN runtime
							END
						),
						2
					) AS runtime,
					ROUND(MIN(cmpl_time), 2) AS cmpl_time
				FROM
					runs
				GROUP BY
					program,
					dataset,
					workers,
					engine
			)
	)
GROUP BY
	program,
	dataset,
	workers
HAVING (
	program = "ddisasm" and dataset = "z3" or
	program = "crdt" and dataset = "crdt " or
	program = "borrow" and dataset = "borrow" or
	program = "cspa" and dataset = "postgresql" or
	program = "csda" and dataset = "postgresql" or
	program = "csda" and dataset = "linux" or
	program = "andersen" and dataset = "500000 " or
	program = "bipartite" and dataset = "mind" or
	program = "bipartite" and dataset = "netflix" or
	program = "reach" and dataset = "livejournal" or
	program = "dyck" and dataset = "postgre" or
	program = "tc" and dataset = "G10K-0.001" or
	program = "sg" and dataset = "G10K-0.001"
)
ORDER BY
	program,
	dataset,
	workers