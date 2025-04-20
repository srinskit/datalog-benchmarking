host=$node0

# Exit script on error
set -e

export PROJECT_ROOT=$(pwd)

resultdir="dlbench-results"
basedir=$(pwd)
launcher="$basedir/launch.sh"
ts=$(date +"%m-%d-%H-%M-%S")
folder="$resultdir/result$ts"
mkdir -p $folder

pushd $folder
$launcher $host $basedir/payload-recstep/
$launcher $host $basedir/payload-ddlog/
$launcher $host $basedir/payload-flowlog/
$launcher $host $basedir/payload-flowlog1/
$launcher $host $basedir/payload-souffle-intptr/
$launcher $host $basedir/payload-souffle-cmpl/
popd

echo $folder