#!/bin/bash

set -ueo pipefail

NUM_NODES=$1  #num pods
NPROCS=$2     #num gpus/pod
GRAD_ACCUM=$3 #num grad accum steps
PROFILE=$4    #turn nsys profiling on/off 1/0
MODEL=$5 #$5 #model string
RUNID=$6

#unique tag
TAG=${NUM_NODES}_${NPROCS}_${GRAD_ACCUM}_${PROFILE}_${MODEL}_${RUNID}

NUM_ITER=10
BS=32
SEQ_LEN=1024

BS_TOTAL=$(($BS * $SEQ_LEN * $GRAD_ACCUM*$NUM_NODES*$NPROCS))

#log folder
LOG_LOC=/tmp
PERM_LOG_LOC=/workspace/data/experiments/logs_profile${PROFILE}_model${MODEL}
if [ ! -d $PERM_LOG_LOC ]
then
	mkdir -p $PERM_LOG_LOC
fi

#log file
LOG_FILE=stdout_npods${NUM_NODES}_nprocs${NPROCS}_numiter${NUM_ITER}_gradaccum${GRAD_ACCUM}_bs${BS}_seq${SEQ_LEN}_totalbs${BS_TOTAL}_runid${RUNID}.log

#profile file
if [ $PROFILE -eq 1 ]
then
	PROFILE_FILE=profile_npods${NUM_NODES}_nprocs${NPROCS}_numiter${NUM_ITER}_gradaccum${GRAD_ACCUM}_bs${BS}_seq${SEQ_LEN}_totalbs${BS_TOTAL}_runid${RUNID}.nsys-rep
fi

NODE_RANK=${JOB_COMPLETION_INDEX}

echo "NUM PODS : $NUM_NODES" | tee $LOG_LOC/$LOG_FILE
echo "NUM PROCS: $NPROCS" | tee -a $LOG_LOC/$LOG_FILE
echo "NUM_ITER  : $NUM_ITER" | tee -a $LOG_LOC/$LOG_FILE
echo "MODEL    : $MODEL" | tee - a $LOG_LOC/$LOG_FILE
echo "BS        : $BS" | tee -a $LOG_LOC/$LOG_FILE
echo "SEQ LEN   : $SEQ_LEN" | tee -a $LOG_LOC/$LOG_FILE
echo "GRAD ACCUM: $GRAD_ACCUM" | tee -a $LOG_LOC/$LOG_FILE
echo "BS TOTAL  : $BS_TOTAL" | tee -a $LOG_LOC/$LOG_FILE
echo "LOG FILE: $LOG_LOC/$LOG_FILE" | tee -a $LOG_LOC/$LOG_FILE
echo "NODE RANK: $NODE_RANK" | tee -a $LOG_LOC/$LOG_FILE
echo "PROFILE  : $PROFILE" | tee -a $LOG_LOC/$LOG_FILE
echo "TAG      : $TAG" | tee -a $LOG_LOC/$LOG_FILE
echo "RUNID    : $RUNID" | tee -a $LOG_LOC/$LOG_FILE

echo "DEBUG"
echo "/workspace/data/shared_ip_${TAG}_${NODE_RANK}"
echo `hostname -i` > /workspace/data/shared_ip_${TAG}_${NODE_RANK}
cat /workspace/data/shared_ip_${TAG}_${NODE_RANK}
ls /workspace/data/shared_ip*

#wait till all pods write their ips to shared volume
while [ `ls /workspace/data/shared_ip_${TAG}_* | wc -l` -ne $NUM_NODES ]
do
	sleep 1
	echo "Waiting for files..." | tee -a $LOG_LOC/$LOG_FILE
done

#read ip:port for master
MASTER_ADDR=$(cat /workspace/data/shared_ip_${TAG}_0)
MASTER_PORT=29500

#collect network stats
echo "Dumping initial: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

#profiling and logging on rank 0 node only
if [ $NODE_RANK -eq 0 ]
then
	if [ $PROFILE -eq 0 ]
	then
		torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/data/llm.c/train_gpt2.py --input_bin "/workspace/data/llm.c/dev/data/fineweb10B/fineweb_train_*.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 2>&1 | tee -a $LOG_LOC/$LOG_FILE
	elif [ $PROFILE -eq 1 ]
	then
		nsys profile --output $LOG_LOC/$PROFILE_FILE torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/data/llm.c/train_gpt2.py --input_bin "/workspace/data/llm.c/dev/data/fineweb10B/fineweb_train_*.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 2>&1 | tee -a $LOG_LOC/$LOG_FILE
	else
		echo "invalid profile option: $PROFILE"
	fi

	#collect network stats
        echo "Dumping final: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
        cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

	#copy log file from container to shared volume
	echo "Copying $LOG_LOC/$LOG_FILE to $PERM_LOG_LOC/$LOG_FILE" | tee -a $LOG_LOC/$LOG_FILE
	cp $LOG_LOC/$LOG_FILE $PERM_LOG_LOC/$LOG_FILE
	
	#remove files with ips
	rm /workspace/data/shared_ip_${TAG}_*

else
	torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NPROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/data/llm.c/train_gpt2.py --input_bin "/workspace/data/llm.c/dev/data/fineweb10B/fineweb_train_*.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1

fi

#sleep 1000
