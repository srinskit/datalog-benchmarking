set export
set working-directory := '..'

node := "$node0"
result_dir := "dlbench-results"

default:
	@just --list --unsorted

validate:
	[ -n "{{node}}" ];

setup: (validate)
	ssh -t {{node}}

ssh inst: (validate)
	ssh -A -t {{node}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; exec \$SHELL -l"

mkscreen inst: (validate)
	ssh -A -t {{node}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; screen -S {{inst}};"

chscreen inst: (validate)
	ssh -A -t {{node}} "screen -r {{inst}};"


