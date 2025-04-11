set export
set working-directory := '..'

result_dir := "dlbench-results"

default:
	@just --list --unsorted

csv folder:
	./log2csv.sh "{{result_dir}}/{{folder}}"

import folder:
	./log2csv.sh "{{result_dir}}/{{folder}}" > /tmp/dlbench_results
	cat /tmp/dlbench_results | wc -l
	sqlite3 $sqldb "select count(*) from runs;"
	sqlite3 $sqldb ".mode csv" ".import /tmp/dlbench_results runs" ".exit"
	sqlite3 $sqldb "select count(*) from runs;"

import-latest: (import `ls -t dlbench-results | head -n1`)

export file:
	sqlite3 data.db -csv -header < evalsql/runtime.sql > {{file}}

size:
	sqlite3 $sqldb "select count(*) from runs;"

latest:
	sqlite3 $sqldb "select max(folder) from runs;"

oldest:
	sqlite3 $sqldb "select min(folder) from runs;"
