#!/bin/bash

set -ueo pipefail

NUM_NODES=$1  #num pods
NPROCS=$2     #num gpus/pod
PROFILE=$3    #turn nsys profiling on/off 1/0
RUNID=$4

export NODE_RANK=$(hostname | awk -F'-' '{print $NF}')

#unique tag
TAG=rank${NODE_RANK}_numnodes${NUM_NODES}_numprocs${NPROCS}_profile${PROFILE}_runid${RUNID}

#log folder
LOG_LOC=/tmp

#log file
LOG_FILE=stdout_${TAG}.log

#profile file
if [ $PROFILE -eq 1 ]
then
	PROFILE_FILE=profile_${TAG}.nsys-rep
fi

echo "Hostname:", $HOSTNAME
export MASTER_ADDR=torch-allreduce-test-0.torchrun-multipod
export MASTER_PORT=29500

echo "NUM PODS : $NUM_NODES" | tee $LOG_LOC/$LOG_FILE
echo "NUM PROCS: $NPROCS" | tee -a $LOG_LOC/$LOG_FILE
echo "LOG FILE: $LOG_LOC/$LOG_FILE" | tee -a $LOG_LOC/$LOG_FILE
echo "NODE RANK: $NODE_RANK" | tee -a $LOG_LOC/$LOG_FILE
echo "PROFILE  : $PROFILE" | tee -a $LOG_LOC/$LOG_FILE
echo "TAG      : $TAG" | tee -a $LOG_LOC/$LOG_FILE
echo "RUNID    : $RUNID" | tee -a $LOG_LOC/$LOG_FILE
#echo "NCCL_SOCKET_NTHREADS : $NCCL_SOCKET_NTHREADS" | tee -a $LOG_LOC/$LOG_FILE
#echo "NCCL_NSOCKS_PERTHREAD: $NCCL_NSOCKS_PERTHREAD" | tee -a $LOG_LOC/$LOG_FILE

#dump env variables
#export NCCL_SOCKET_NTHREADS=$NCCL_SOCKET_NTHREADS
#export NCCL_NSOCKS_PERTHREAD=$NCCL_NSOCKS_PERTHREAD
echo "--------------------------" | tee -a $LOG_LOC/$LOG_FILE
env | tee -a $LOG_LOC/$LOG_FILE
echo "--------------------------" | tee -a $LOG_LOC/$LOG_FILE

#collect network stats
echo "Dumping initial: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

#profiling and logging on rank 0 node only
if [ $NODE_RANK -eq 0 ]
then
	if [ $PROFILE -eq 0 ]
	then
		torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/ar.py 2>&1 | tee -a $LOG_LOC/$LOG_FILE
	elif [ $PROFILE -eq 1 ]
	then
		nsys profile --output $LOG_LOC/$PROFILE_FILE torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/ar.py 2>&1 | tee -a $LOG_LOC/$LOG_FILE
	else
		echo "invalid profile option: $PROFILE"
	fi

	#collect network stats
        echo "Dumping final: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
        cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

else
	torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/ar.py 2>&1 | tee -a $LOG_LOC/$LOG_FILE

fi

sleep infinity
