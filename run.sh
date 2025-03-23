host=$1

# Exit script on error
set -e

resultdir="dlbench-results"
basedir=$(pwd)
launcher="$basedir/launch.sh"
ts=$(date +"%m-%d-%H-%M-%S")
folder="$resultdir/result$ts"
mkdir -p $folder

pushd $folder
$launcher $host $basedir/payload-recstep/
$launcher $host $basedir/payload-ddlog/
$launcher $host $basedir/payload-souffle-cmpl/
$launcher $host $basedir/payload-souffle-intptr/
$launcher $host $basedir/payload-eclair/
popd

echo $folder