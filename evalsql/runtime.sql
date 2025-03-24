SELECT
	program,
	dataset,
	workers,
	MAX(
		CASE
			WHEN engine = 'eclair' THEN display
		END
	) AS eclair,
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
	) AS ddlog
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
					ELSE (
						CASE
							WHEN tout > 0 THEN 'TOUT'
							ELSE (
								CASE
									WHEN dnf > 0
									THEN 'DNF'
									ELSE 'N/A'
								END
							)
						END
					)
				END
			) AS display
		FROM
			(
				SELECT
					program,
					dataset,
					workers,
					engine,
					COUNT() AS total_runs,
					COUNT(
						CASE
							WHEN status = 'CMP'
							AND output <> ''
							AND output <> '0' THEN 1
						END
					) AS cmp,
					COUNT(
						CASE
							WHEN status = 'TOUT' THEN 1
						END
					) AS tout,
					COUNT(
						CASE
							WHEN status = 'DNF'
							OR (
								status = 'CMP'
								AND (
									output = ''
									OR output = '0'
								)
							) THEN 1
						END
					) AS dnf,
					ROUND(
						AVG(
							CASE
								WHEN status = 'CMP'
								AND output <> ''
								AND output <> '0' THEN runtime
							END
						),
						2
					) AS runtime,
					ROUND(AVG(runtime), 2) AS dirty_runtime
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
ORDER BY
	program,
	dataset,
	workers