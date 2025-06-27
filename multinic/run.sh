#!/bin/bash

set -uex 

./assign_ips.sh

sleep 10

#export TORCH_LOGS=distributed
#export TORCH_DISTRIBUTED_DEBUG=DETAIL

#export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5
export NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5
#export NCCL_IB_HCA=mlx5_3,mlx5_4,mlx5_5
export NCCL_IB_GID_INDEX=3
export NCCL_NET_PLUGIN=ib
export NCCL_IB_TIMEOUT=22

export NCCL_IB_CUDA_SUPPORT=1
export NCCL_SOCKET_IFNAME=eno7np0

export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,NET,GRAPH
export NCCL_TOPO_DUMP_FILE=/tmp/topo.xml

POD_NAME=${POD_NAME:-$(hostname)}
POD_INDEX=${POD_NAME##*-}

POD0_IPS=(192.168.90.100 192.168.91.100 192.168.92.100 192.168.93.100)
POD1_IPS=(192.168.90.101 192.168.91.101 192.168.92.101 192.168.93.101)

if [ $POD_INDEX -eq 0 ]
then
	for ip in "${POD1_IPS[@]}"
	do
		ping -c 2 -W 1 $ip
	done
fi

if [ $POD_INDEX -eq 1 ]
then
        for ip in "${POD0_IPS[@]}"
        do
                ping -c 2 -W 1 $ip
        done
fi


#sleep infinity

#RDMA
export NCCL_IB_DISABLE=0
export NCCL_IB_CUDA_SUPPORT=0
export NCCL_DMABUF_ENABLE=0
export NCCL_GDR_LEVEL=LOC


#GDR
#export NCCL_IB_DISABLE=0
#export NCCL_IB_CUDA_SUPPORT=1
#export NCCL_DMABUF_ENABLE=1
##export NCCL_GDR_LEVEL=PXB
#export NCCL_GDR_LEVEL=PXB
#export NCCL_NET_GDR_READ=1

#torchrun \
#  --nproc_per_node=4 \
#  --nnodes=2 \
#  --node_rank=$POD_INDEX \
#  --master_addr=192.168.90.100 \
#  --master_port=29500 \
#  ar.py >& /workspace/log.txt
#  torchrun_test.py

NUM_NODES=2
NPROCS=4
NUM_ITER=10
BS=32
SEQ_LEN=1024
GRAD_ACCUM=1
BS_TOTAL=$(($BS * $SEQ_LEN * $GRAD_ACCUM*$NUM_NODES*$NPROCS))

torchrun --nnodes=$NUM_NODES --nproc-per-node=$NPROCS --node-rank=${POD_INDEX} --master-addr=192.168.90.100 --master-port=29500 /workspace/llm.c/train_gpt2.py --input_bin "/workspace/llm.c/dev/data/fineweb10B/fineweb_train_000001.bin" --write_tensors 0 --model d12 --batch_size ${BS} --sequence_length ${SEQ_LEN} --total_batch_size ${BS_TOTAL} --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations ${NUM_ITER} --weight_decay 0.1 2>&1 | tee -a /workspace/log.txt


sleep infinity
