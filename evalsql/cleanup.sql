UPDATE runs
SET
	program = 'doop'
WHERE
	program IN ('batik', 'biojava', 'eclipse', 'xalan', 'zxing');

UPDATE runs
SET
	program = REPLACE(program, '-reach', '')
WHERE
	program LIKE 'diamond-reach%';

UPDATE runs
SET
	program = 'ddisasm'
WHERE
	program in ('ddisasm-z3', 'ddisasm-cvc5');

UPDATE runs
SET
	program = REPLACE(program, 'ddisasm-ddisasm', 'ddisasm')
WHERE
	program like 'ddisasm-ddisasm-%';

UPDATE runs
SET
	program = REPLACE(program, 'doop-doop', 'doop')
WHERE
	program LIKE 'doop-doop%';
