#!/bin/bash

set -euo pipefail

RUN_ID=$1
IF=eno5np0

POD_NAME=${POD_NAME:-$(hostname)}
POD_INDEX=${POD_NAME##*-}
NODE_RANK=$POD_INDEX

IP_FNAME="/workspace/data/rank0_ip_$RUN_ID"

if [[ $NODE_RANK -eq 0 ]]
then
	ip=$(ifconfig $IF | grep "inet " | awk '{print $2}')
        echo "Writing ip to $IP_FNAME"
        echo $ip > $IP_FNAME
fi

while [[ ! -f $IP_FNAME ]]
do
	sleep 1
	echo "Waiting for shared IP file: $IP_FNAME"
done

export MASTER_ADDR=$(cat $IP_FNAME)
export MASTER_PORT=29500

