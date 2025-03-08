source .env
driver=$1
dst_host=$2
result_dir="dlbench-results"
rsync -ah --exclude="$result_dir" $PWD $driver:~/$dst_host/
