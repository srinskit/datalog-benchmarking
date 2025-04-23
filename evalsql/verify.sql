SELECT
	A.pg,
	A.dataset,
	distinct_outputs,
	B.output,
	engine_count,
	engines,
	programs
FROM
	(
		SELECT
			(CASE when instr(program, '-') > 0 THEN substr(program, 0, instr(program, '-')) ELSE program END) as pg,
			dataset,
			COUNT(DISTINCT output) AS distinct_outputs
		FROM
			runs
		WHERE
			status = 'CMP' and output <> ''
		GROUP BY
			pg,
			dataset
	) A
	LEFT JOIN (
		SELECT
			(CASE when instr(program, '-') > 0 THEN substr(program, 0, instr(program, '-')) ELSE program END) as pg,
			dataset,
			output,
			COUNT(DISTINCT engine) engine_count,
			GROUP_CONCAT(DISTINCT engine) engines,
			GROUP_CONCAT(DISTINCT program) programs
		FROM
			runs
		WHERE
			status = 'CMP' and output <> ''
		GROUP BY
			pg,
			dataset,
			output
	) B ON A.pg = B.pg
	AND A.dataset = B.dataset
ORDER BY
	distinct_outputs DESC,
	A.pg,
	A.dataset,
	engine_count DESC;
