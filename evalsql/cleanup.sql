UPDATE runs
SET
	program = 'doop'
WHERE
	program IN ('batik', 'biojava', 'eclipse', 'xalan', 'zxing');

UPDATE runs
SET
	engine = 'flowlog'
WHERE
	engine = 'eclair';
