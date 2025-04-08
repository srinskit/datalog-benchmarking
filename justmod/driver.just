set export
set working-directory := '..'

result_dir := "dlbench-results"
ssh_config := "
Host *
	Controlmaster auto
	Controlpath /tmp/ssh-%r@%h:%p
	ControlPersist yes
"

default:
	@just --list --unsorted


setup driver:
	ssh -t {{driver}} "sudo apt update; sudo apt install screen; echo '{{ssh_config}}' > .ssh/config; cat .ssh/config; "

ssh driver inst:
	ssh -A -t {{driver}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; exec \$SHELL -l"

mkscreen driver inst: (push driver inst)
	ssh -A -t {{driver}} "mkdir -p "{{inst}}/cloudlab-auto"; cd "{{inst}}/cloudlab-auto"; screen -S {{inst}};"

chscreen driver inst: 
	ssh -A -t {{driver}} "screen -r {{inst}};"

push driver inst:
	rsync -ah --exclude="{{result_dir}}" $PWD {{driver}}:~/{{inst}}/

pull driver inst:
	rsync -ah {{driver}}:"~/{{inst}}/cloudlab-auto/{{result_dir}}/" "$PWD/{{result_dir}}/"
