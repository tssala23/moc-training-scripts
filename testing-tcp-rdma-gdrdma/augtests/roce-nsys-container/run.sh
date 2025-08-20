#!/bin/bash

set -ueo pipefail

#Step 0: experiment args
NUM_NODES=$1		 #number of nodes/pods
NUM_PROCS=$2 		 #number of gpus per node/pod
PROFILE=$3   		 #use nsys or not
TYPE=$4      		 #protocol for transportation
NUM_NICS=$5  		 #[1,4] int
RUNID=$6     		 #special tag
NCCL_SOCKET_NTHREADS=$7  #
NCCL_NSOCKS_PERTHREAD=$8 #
BUCKET_CAP=$9

#Step 2: experiment parameters
BS=32 #batch size per proc/gpu
SEQ_LEN=1024 #seq length for each sample in batch
GRAD_ACCUM=1 #gradient accumulation
BS_TOTAL=$(($BS * $SEQ_LEN * $GRAD_ACCUM*$NUM_NODES*$NUM_PROCS)) #effective batch size
MODEL=d12 #model tag
NUM_ITER=10

POD_NAME=${POD_NAME:-$(hostname)}
POD_INDEX=${POD_NAME##*-}
NODE_RANK=$POD_INDEX

TAG=npods${NUM_NODES}_nprocs${NUM_PROCS}_profile${PROFILE}_type${TYPE}_numnics${NUM_NICS}_runid${RUNID}_nthreads${NCCL_SOCKET_NTHREADS}_nsocks${NCCL_NSOCKS_PERTHREAD}_bucketsize${BUCKET_CAP}

#get master addr
. ./get_master.sh $TAG

echo "MASTER ADDR: $MASTER_ADDR"
echo "MASTER PORT: $MASTER_PORT"

#Step 3: debug params
echo "Setting debug parameters"
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,NET,GRAPH,GDR

LOG_LOC=/tmp/logs
if [ ! -d $LOG_LOC ]
then
        mkdir -p $LOG_LOC
fi
LOG_FILE=stdout_${TAG}.log
export NCCL_TOPO_DUMP_FILE=$LOG_LOC/topo.xml
export NCCL_DEBUG_FILE=$LOG_LOC/nccl_debug_$TAG

if [ $PROFILE -eq 1 ]
then
        PROFILE_FILE=profile_${TAG}.nsys-rep
fi

#Step 4: NIC settings - construct NCCL_IB_HCA
function construct_nicname {
	echo "Constructing NCCL_IB_HCA"
	NIC_LIST=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
	IF_LIST=("eno6np0" "eno5np0" "eno8np0" "eno7np0")
	NUM_NICS=$1

	NCCL_IB_HCA=""
	#NCCL_SOCKET_IFNAME=""
	for nic in ${!NIC_LIST[@]}
	do
        	if [[ $nic -lt $NUM_NICS ]]
        	then
                	NCCL_IB_HCA+=${NIC_LIST[nic]}","
			#NCCL_SOCKET_IFNAME+=${IF_LIST[nic]}","
        	else
                	break
        	fi
	done
	NCCL_IB_HCA=$(echo $NCCL_IB_HCA | sed s:",$"::g)
	#NCCL_SOCKET_IFNAME=$(echo $NCCL_SOCKET_IFNAME | sed s:",$"::g)
}

construct_nicname $NUM_NICS

echo "Done with constructing NCCL_IB_HCA: $NCCL_IB_HCA"
export NCCL_IB_HCA
export NCCL_SOCKET_IFNAME=eno8np0
export NCCL_IB_GID_INDEX=3
export NCCL_NET_PLUGIN=ib
export NCCL_IB_TIMEOUT=22

echo "Choosing env vars for protocol $TYPE"
#Step 5: protocol options
if [ $TYPE == "TCP" ]
then
        echo "TYPE=$TYPE" | tee -a $LOG_LOC/$LOG_FILE
        export NCCL_IB_DISABLE=1
        export NCCL_SOCKET_NTHREADS
        export NCCL_NSOCKS_PERTHREAD
        unset NCCL_IB_HCA
        unset NCCL_IB_GID_INDEX

elif [ $TYPE == "RDMA" ]
then
        echo "TYPE=$TYPE" | tee -a $LOG_LOC/$LOG_FILE
        export NCCL_IB_DISABLE=0
        export NCCL_IB_CUDA_SUPPORT=0
        export NCCL_DMABUF_ENABLE=0
        export NCCL_GDR_LEVEL=LOC

elif [ $TYPE == "GDRNOREAD" ]
then
        echo "TYPE=$TYPE" | tee -a $LOG_LOC/$LOG_FILE
        export NCCL_IB_DISABLE=0
        export NCCL_IB_CUDA_SUPPORT=1
        export NCCL_DMABUF_ENABLE=1
        #export NCCL_GDR_LEVEL=SYS
        export NCCL_GDR_LEVEL=PXB
        export NCCL_NET_GDR_READ=0

elif [ $TYPE == "GDRWITHREAD" ]
then
        echo "TYPE=$TYPE" | tee -a $LOG_LOC/$LOG_FILE
        export NCCL_IB_DISABLE=0
        export NCCL_IB_CUDA_SUPPORT=1
        export NCCL_DMABUF_ENABLE=1
        #export NCCL_GDR_LEVEL=SYS
        export NCCL_GDR_LEVEL=PXB
        export NCCL_NET_GDR_READ=1

else
        echo "Exiting ... TYPE=$TYPE not valid"
        exit
fi

#Step 6: dump vars
echo "Hostname:", $HOSTNAME | tee -a $LOG_LOC/$LOG_FILE
echo "Pod Name:", $POD_NAME | tee -a $LOG_LOC/$LOG_FILE
echo "NUM PODS : $NUM_NODES" | tee -a $LOG_LOC/$LOG_FILE
echo "NUM PROCS: $NUM_PROCS" | tee -a $LOG_LOC/$LOG_FILE
echo "NUM NICS: $NUM_NICS" | tee -a $LOG_LOC/$LOG_FILE
echo "NUM_ITER  : $NUM_ITER" | tee -a $LOG_LOC/$LOG_FILE
echo "MODEL    : $MODEL" | tee -a $LOG_LOC/$LOG_FILE
echo "BS        : $BS" | tee -a $LOG_LOC/$LOG_FILE
echo "SEQ LEN   : $SEQ_LEN" | tee -a $LOG_LOC/$LOG_FILE
echo "GRAD ACCUM: $GRAD_ACCUM" | tee -a $LOG_LOC/$LOG_FILE
echo "BS TOTAL  : $BS_TOTAL" | tee -a $LOG_LOC/$LOG_FILE
echo "LOG FILE: $LOG_LOC/$LOG_FILE" | tee -a $LOG_LOC/$LOG_FILE
echo "NODE RANK: $NODE_RANK" | tee -a $LOG_LOC/$LOG_FILE
echo "PROFILE  : $PROFILE" | tee -a $LOG_LOC/$LOG_FILE
echo "TAG      : $TAG" | tee -a $LOG_LOC/$LOG_FILE
echo "RUNID    : $RUNID" | tee -a $LOG_LOC/$LOG_FILE
echo "MASTER ADDR: $MASTER_ADDR" | tee -a $LOG_LOC/$LOG_FILE
echo "MASTER PORT: $MASTER_PORT" | tee -a $LOG_LOC/$LOG_FILE
echo "NCCL_SOCKET_NTHREADS : $NCCL_SOCKET_NTHREADS" | tee -a $LOG_LOC/$LOG_FILE
echo "NCCL_NSOCKS_PERTHREAD: $NCCL_NSOCKS_PERTHREAD" | tee -a $LOG_LOC/$LOG_FILE
echo "BUCKET CAP: $BUCKET_CAP" | tee -a $LOG_LOC/$LOG_FILE

#Step 7: Run job
echo "------START: ENV VARS------------------" | tee -a $LOG_LOC/$LOG_FILE
env | tee -a $LOG_LOC/$LOG_FILE
echo "------STOP : ENV VARS--------------------" | tee -a $LOG_LOC/$LOG_FILE

echo "Dumping initial: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

#nstat --reset > /dev/null
#echo "Writing nstat pre file"
#nstat > $LOG_LOC/$NSTAT_PRE_FILE

#echo "Date:" `date | tee -a $LOG_LOC/$LOG_FILE`
#nvidia-smi dmon -s mte --gpm-metrics 20,21,60,61 -o DT >& smi_log &

#declare -a SAMPLER_PIDS=()
#stdbuf -oL -eL nvidia-smi dmon -s mte --gpm-metrics 20,21,60,61 -o DT > $LOG_LOC/smi.dmon 2>& 1 &
#SAMPLE_PIDS+=("$!")

#( while :;
#	do
#		echo "===== $(date -Is) ======" >> "$LOG_LOC/dmabuf.log"
#		grep -R . /mnt/debugfs/dma_buf >> "$LOG_LOC/dmabuf.log" 2>/dev/null || true
#		echo >> "$LOG_LOC/dmabuf.log"
#	done ) &
#SAMPLE_PIDS+=("$!")

#cleanup() {
#	for pid in "${SAMPLE_PIDS[@]}"
#	do
#		kill "$pid" 2>/dev/null
#	done
#	for pid in "${SAMPLE_PIDS[@]}"
#	do
#		wait "$pid" 2>/dev/null
#	done
#}
#trap cleanup EXIT INT TERM

OUT_LOC=$LOG_LOC ./collect_snapshot.sh start 
if [ $NODE_RANK -eq 0 ]
then
        if [ $PROFILE -eq 0 ]
        then
                torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NUM_PROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/llm.c/train_gpt2.py --input_bin "/workspace/llm.c/dev/data/fineweb10B/fineweb_train_000001.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 --bucket_cap $BUCKET_CAP 2>&1 | tee -a $LOG_LOC/$LOG_FILE
        elif [ $PROFILE -eq 1 ]
        then
                nsys profile --trace=cuda,nvtx,osrt --gpu-metrics-devices=all --gpu-metrics-set=gh100 --output $LOG_LOC/$PROFILE_FILE torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NUM_PROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/llm.c/train_gpt2.py --input_bin "/workspace/llm.c/dev/data/fineweb10B/fineweb_train_000001.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 --bucket_cap $BUCKET_CAP 2>&1 | tee -a $LOG_LOC/$LOG_FILE
        else
                echo "invalid profile option: $PROFILE"
        fi

        #collect network stats
        echo "Dumping final: /proc/net/dev" | tee -a $LOG_LOC/$LOG_FILE
        cat /proc/net/dev >> $LOG_LOC/$LOG_FILE

else
        torchrun --nnodes=${NUM_NODES} --nproc-per-node=${NUM_PROCS} --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} /workspace/llm.c/train_gpt2.py --input_bin "/workspace/llm.c/dev/data/fineweb10B/fineweb_train_000001.bin" --write_tensors 0 --model ${MODEL} --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 --bucket_cap $BUCKET_CAP

fi

OUT_LOC=$LOG_LOC ./collect_snapshot.sh end

#echo "Writing nstat out file"
#nstat > $LOG_LOC/$NSTAT_POST_FILE

if [ $PROFILE -eq 1 ]
then
        nsys stats $LOG_LOC/$PROFILE_FILE >& $LOG_LOC/nsys_summary
fi

echo "Date:" `date | tee -a $LOG_LOC/$LOG_FILE`

#sleep infinity
