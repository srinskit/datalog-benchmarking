source .env
driver=$1
dst_host=$2
result_dir="dlbench-results"
rsync -ah $driver:"~/$dst_host/cloudlab-auto/$result_dir/" "$PWD/$result_dir/"
