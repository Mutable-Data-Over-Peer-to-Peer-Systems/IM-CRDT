#!/bin/bash
code=$1
numberPeers=$2
numberUpdates=$3
nbpeersUpdating=$4
file_NODES=$5
echo "/**"
echo " * Beggining the CRDT IPFS setup"
echo " */"

USER_LOGIN_NAME=$(id -un)
USER_GROUP_ID=$(id -g)
USER_GROUP_NAME=$(id -gn)

numberPeers=$2
DATE=$(date +%s)

TMP_DIR=/tmp/$DATE'-'$$'-CRDTIPFS'

echo $TMP_DIR

SLAVES=$(cat other)
MASTER=$(cat bootstrap)


echo  "SLAVES"
echo $SLAVES
echo "MASTER"
echo $MASTER
echo "Building the  GO implementation"

for SLAVE in $SLAVES
do
scp $code root@$SLAVE:~/$code &
done
scp $code root@$MASTER:~/$code
sleep 60s
for SLAVE in $SLAVES
do
ssh root@$SLAVE "sh -c 'tar -xvf go_trans.tar.gz > tar.log && cd CRDT_IPFS && /usr/local/go/bin/go mod tidy > build.log && /usr/local/go/bin/go build > build.log'" > /dev/null  2>&1 & 
done
ssh root@$MASTER "sh -c 'tar -xvf go_trans.tar.gz > tar.log && cd CRDT_IPFS && /usr/local/go/bin/go mod tidy > build.log && /usr/local/go/bin/go build > build.log'" > build.log 2>&1

sleep 90s

echo "running the bootstrap in ${MASTER} node1"
ssh root@$MASTER "rm  CRDT_IPFS/ID"
ssh root@$MASTER "mkdir  CRDT_IPFS/node1"
ssh root@$MASTER "mkdir  CRDT_IPFS/node1/rootNode"
ssh root@$MASTER "mkdir  CRDT_IPFS/node1/remote"
ssh root@$MASTER "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --encode sataislifesataisloveanditsfor32b --mode BootStrap --name node1 --updatesNB $numberUpdates --updating true  > /dev/null & '"  &
sleep 30s
BOOTSTRAPIDS=$(ssh root@$MASTER "sh -c 'cat ./CRDT_IPFS/ID2'")
BOOTSTRAPID=""
#echo "reading file $BOOTSTRAPIDS"
for ID in $BOOTSTRAPIDS
do
#echo "analysing $ID"
if [[ "$ID" == *"/ip4"* ]]; then
  if [[ "$ID" == *"/127.0.0"* ]]; then
#    "It's a Local IP, not interesting"
    continue
  else
#    "bootstrap IP is usable"
    BOOTSTRAPID=$ID
  fi
fi

done
echo "running the lisnteners -- FIRST"
x=$(( $nbpeersUpdating - 1 ))
echo "x: "$x
for SLAVE in $SLAVES
do

ssh root@$SLAVE "rm -rf CRDT_IPFS/node1"
ssh root@$SLAVE "mkdir  CRDT_IPFS/node1"
ssh root@$SLAVE "mkdir  CRDT_IPFS/node1/rootNode"
ssh root@$SLAVE "mkdir  CRDT_IPFS/node1/remote"


echo $SLAVE
ssh root@$SLAVE "ls -lah  CRDT_IPFS/node1/rootNode"

#ssh root@$SLAVE "rm -rf CRDT_IPFS/node2"
#ssh root@$SLAVE "rm -rf CRDT_IPFS/node3"
#ssh root@$SLAVE "rm -rf CRDT_IPFS/node4"
if [[ $x > 0 ]]
then
echo "updating"

ssh root@$SLAVE "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --encode sataislifesataisloveanditsfor32b --mode update --ni ${BOOTSTRAPID} --name node1 --updatesNB $numberUpdates --updating true  > /dev/null &'" &
x=$(( $x - 1 ))
else
echo "NOT updating"
ssh root@$SLAVE "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --encode sataislifesataisloveanditsfor32b --mode update --ni ${BOOTSTRAPID} --name node1 --updatesNB $numberUpdates  > /dev/null &'" &
fi

#ssh root@$SLAVE "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --mode update --ni ${BOOTSTRAPID} --name node2 > out.log &'"&
#ssh root@$SLAVE "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --mode update --ni ${BOOTSTRAPID} --name node3 > out.log &'"&
#ssh root@$SLAVE "sh -c 'cd CRDT_IPFS && ./IPFS_CRDT --mode update --ni ${BOOTSTRAPID} --name node4 > out.log &'"&

done
echo "All listeners have been started"
