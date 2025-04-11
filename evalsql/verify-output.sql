SELECT
	A.program,
	A.dataset,
	distinct_outputs,
	B.output,
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
			status = 'CMP' and output <> ''
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
			status = 'CMP' and output <> ''
		GROUP BY
			program,
			dataset,
			output
	) B ON A.program = B.program
	AND A.dataset = B.dataset
-- WHERE A.program LIKE '%reach%' and A.dataset = 'web-stanford'
ORDER BY
	distinct_outputs DESC,
	engine_count DESC,
	A.program,
	A.dataset;