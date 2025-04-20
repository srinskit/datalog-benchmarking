UPDATE runs
SET
	program = 'doop'
WHERE
	program IN ('batik', 'biojava', 'eclipse', 'xalan', 'zxing');

UPDATE runs
SET
	engine = 'flowlog'
WHERE
	engine = 'flowlog';

UPDATE runs
SET
	program = 'doop'
WHERE
	program LIKE '%doop_';

UPDATE runs
SET
	program = REPLACE(program, '-reach', '')
WHERE
	program LIKE 'diamond-reach%';

UPDATE runs
SET
	program = 'ddisasm'
WHERE
	program like 'ddisasm-%';

UPDATE runs
SET
	program = REPLACE(program, 'doop-doop', 'doop')
WHERE
	program LIKE 'doop-doop%';
