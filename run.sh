host=$1

./launch.sh $host payload-eclair/
./launch.sh $host payload-souffle-cmpl/
./launch.sh $host payload-souffle-intptr/
./launch.sh $host payload-recstep/
./launch.sh $host payload-ddlog/

dlbench plot --last 5
