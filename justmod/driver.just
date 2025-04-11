set export
set working-directory := '..'

node := "$noded"
result_dir := "dlbench-results"
ssh_config := "
Host *
	Controlmaster auto
	Controlpath /tmp/ssh-%r@%h:%p
	ControlPersist yes
"

default:
	@just --list --unsorted

validate:
	[ -n "{{node}}" ];

setup: (validate)
	ssh -t {{node}} "sudo apt update; sudo apt install screen; echo '{{ssh_config}}' > .ssh/config; cat .ssh/config; "

ssh inst: (validate)
	ssh -A -t {{node}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; exec \$SHELL -l"

mkscreen inst: (validate) (push inst)
	ssh -A -t {{node}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; screen -S {{inst}};"

chscreen inst: (validate)
	ssh -A -t {{node}} "screen -r {{inst}};"

push inst: (validate)
	rsync -ah --exclude="{{result_dir}}" $PWD {{node}}:~/{{inst}}/

pull inst: (validate)
	rsync -ah {{node}}:"~/{{inst}}/cloudlab-auto/{{result_dir}}/" "$PWD/{{result_dir}}/"

