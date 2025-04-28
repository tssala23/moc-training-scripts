#!/bin/bash

# Constants
SEQ_LEN=1024
BS=32
NPROC_PER_NODE=4
NUM_ITER=10
RDZV_BACKEND="c10d"
TRAIN_SCRIPT="train_gpt2.py"

echo "Using TCP"
MTU=1500
for GRAD_ACCUM in {1..10}; do
    WORLD_SIZE=$((NODES * NPROC_PER_NODE))
    TOTAL_BATCH_SIZE=$((BS * SEQ_LEN * GRAD_ACCUM * NODES * NPROC_PER_NODE))
    NCCL_DEBUG=INFO NCCL_DEBUG_SYS=NET NCCL_IB_DISABLE=1 NCCL_SOCKET_IFNAME=eno7np0 GLOO_SOCKET_IFNAME=eno7np0 torchrun --nnodes=$NODES --node-rank=$RANK --nproc_per_node=$NPROC_PER_NODE --rdzv-endpoint=$MASTER_ADDR:$MASTER_PORT --rdzv-backend=$RDZV_BACKEND $TRAIN_SCRIPT --input_bin 'dev/data/fineweb10B/fineweb_train_*.bin' --write_tensors 0 --model d12 --batch_size $BS --sequence_length $SEQ_LEN --total_batch_size $TOTAL_BATCH_SIZE --dtype bfloat16 --compile 1 --tensorcores 1 --flash 1 --num_iterations $NUM_ITER --weight_decay 0.1 > logs/stdout_nnodes${NODES}_nprocs${NPROC_PER_NODE}_numiter${NUM_ITER}_gradaccum${GRAD_ACCUM}_bs${BS}_seq${SEQ_LEN}_totalbs${TOTAL_BATCH_SIZE}_mtu${MTU}_tcp.log
    echo "Done with grad_accum = ${GRAD_ACCUM}"
done



