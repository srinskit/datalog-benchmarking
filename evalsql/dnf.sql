SELECT
	program,
	dataset,
	runtime,
	workers,
	('dlbench plot --graphs m --logs dlbench-results/' || folder || '/' || program || '_' || dataset || '_' || workers || '*' || '.log') AS logs,
	('dlbench-results/' || folder || '/' || program || '_' || dataset || '_' || workers || '_' || engine || '.out') AS p
FROM
	runs
WHERE
	status = 'DNF' --and program in ('sg', 'tc')
order BY
	folder desc