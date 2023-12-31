NumberNodes=$1
NumberUpdates=$2
nbpeersUpdating=$3
file_NODES=$4

echo "start Kadeploy "$(date +"%T")
kadeploy3 -a CRDT_IPFS.yaml > kadeploy.log ;
echo "kadeploy3 done "$(date +"%T")

echo "NumberNodes : $NumberNodes"
cat "$file_NODES" | cut -d'.' -f1 | tail -n "$(( $NumberNodes - 1 ))" > other
head -n 1 "$file_NODES"| cut -d'.' -f1 > bootstrap

./Run_CI.sh go_trans.tar.gz $NumberNodes $NumberUpdates $nbpeersUpdating $file_NODES
echo "waiting Five minute so everybody is connected"
sleep 300s
if [ $NumberUpdates -eq 10 ]
then
echo "sleep 150s"
sleep 100s
fi
if [ $NumberUpdates -eq 100 ]
then
echo "sleep 130s"
sleep 130s
fi
if [ $NumberUpdates -eq 1000 ]
then
echo "sleep 1200s"
for percent in {1..100..10} 
do
echo $(( $percent ))"percent"
sleep 120s
done
fi
if [ $NumberUpdates -eq 10000 ]
then
echo "sleep 10200s - "$(date +"%T")
for percent in {1..100..10} 
do
echo $(( $percent ))"percent"
sleep 1020s
done
fi
./retrieveInfo.sh $NumberNodes $NumberUpdates
sleep 2s
echo "DONE, now retrieve  data and mean!!!"

