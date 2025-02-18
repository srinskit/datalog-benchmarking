host=$1

# Exit script on error
set -e

basedir=$(pwd)
launcher="$basedir/launch.sh"
ts=$(date +"%m-%d-%H-%M-%S")
folder=result"$ts"
mkdir -p $folder

pushd $folder
$launcher $host $basedir/payload-eclair/
$launcher $host $basedir/payload-souffle-cmpl/
$launcher $host $basedir/payload-souffle-intptr/
$launcher $host $basedir/payload-recstep/
$launcher $host $basedir/payload-ddlog/
# dlbench plot --last 5
popd

$basedir/log2sheet.sh $folder
