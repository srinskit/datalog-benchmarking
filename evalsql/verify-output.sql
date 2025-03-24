SELECT
	A.program,
	A.dataset,
	distinct_outputs,
	engine_count,
	engines
FROM
	(
		SELECT
			program,
			dataset,
			COUNT(DISTINCT output) AS distinct_outputs
		FROM
			runs
		WHERE
			status = 'CMP'
		GROUP BY
			program,
			dataset
	) A
	LEFT JOIN (
		SELECT
			program,
			dataset,
			output,
			COUNT(DISTINCT engine) engine_count,
			GROUP_CONCAT(DISTINCT engine) engines
		FROM
			runs
		WHERE
			status = 'CMP'
		GROUP BY
			program,
			dataset,
			output
	) B ON A.program = B.program
	AND A.dataset = B.dataset
ORDER BY
	distinct_outputs,
	A.program,
	A.dataset;