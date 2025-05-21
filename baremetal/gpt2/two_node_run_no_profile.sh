#!/bin/bash

# Constants
SEQ_LEN=1024
BS=32
NPROC_PER_NODE=4
NUM_ITER=10
RDZV_BACKEND="c10d"
TRAIN_SCRIPT="train_gpt2.py"
MASTER_ADDR=$R0 
MASTER_PORT=29500
LOGDIR=validation_noprofile
TUPLES=(
	"16 4"
	#"8 8"
	#"4 16"
	#"2 32"
	#"1 64"
)
MTU_X4=9000
MTU_X8=9000

#MTU1=$MTU_X4 MTU2=$MTU_X8 ~/scripts/set_mtu.sh

for NODES in 2; do
	for TUPLE in "${TUPLES[@]}"; do
		read NCCL_SOCKET_NTHREADS NCCL_NSOCKS_PERTHREAD <<< "$TUPLE"
		for GRAD_ACCUM in 1; do
			echo "Nodes: $NODES ,  Grad_accum: $GRAD_ACCUM"
			WORLD_SIZE=$((NODES * NPROC_PER_NODE))
	    		TOTAL_BATCH_SIZE=$((BS * SEQ_LEN * GRAD_ACCUM * NODES * NPROC_PER_NODE))
			for TYPE in "tcp" "rdma" "gdrdma"; do
				echo "Communication Type: $TYPE"
				mkdir -p $LOGDIR/$TYPE
			PIDS=()
			for RANK in 1 2 3 4 5 6 7 0; do
				if [ "$RANK" -ge "$NODES" ]; then
    					continue
				fi
				CMD="NCCL_SOCKET_NTHREADS=$NCCL_SOCKET_NTHREADS \
				NCCL_NSOCKS_PERTHREAD=$NCCL_NSOCKS_PERTHREAD \
				NCCL_SOCKET_IFNAME=eno6np0 \
				GLOO_SOCKET_IFNAME=eno6np0 \
				NCCL_IB_OOB_IPV6_DISABLE=1 \
				torchrun \
				--nnodes=$NODES \
				--node-rank=$RANK \
		  		--nproc_per_node=$NPROC_PER_NODE \
		  		--rdzv-endpoint=$MASTER_ADDR:$MASTER_PORT \
		  		--rdzv-backend=$RDZV_BACKEND \
		  		$TRAIN_SCRIPT \
		  		--input_bin 'dev/data/fineweb10B/fineweb_train_*.bin' \
		  		--write_tensors 0 \
		  		--model d12 \
		  		--batch_size $BS \
		  		--sequence_length $SEQ_LEN \
		  		--total_batch_size $TOTAL_BATCH_SIZE \
		  		--dtype bfloat16 \
		  		--compile 1 \
		  		--tensorcores 1 \
	  			--flash 1 \
	  			--num_iterations $NUM_ITER \
	  			--weight_decay 0.1 "
				nodeid="N$RANK"
				NODEIP=${!nodeid}
				nodeid_rdma="R$RANK"
				NODERDMAIP=${!nodeid_rdma}
				echo "Rank: $RANK , Regular IP: $NODEIP , Dedicated IP: $NODERDMAIP"
				if [ "$TYPE" = "tcp" ]; then
    					CMD="NCCL_IB_DISABLE=1 $CMD"
				fi
                                if [ "$TYPE" = "rdma" ]; then
                                        CMD="NCCL_IB_DISABLE=0 NCCL_IB_CUDA_SUPPORT=0 NCCL_DMABUF_ENABLE=0 NCCL_GDR_LEVEL=LOC NCCL_IB_HCA=mlx5_2 $CMD"
                                fi
                                if [ "$TYPE" = "gdrdma" ]; then
                                        CMD="NCCL_IB_DISABLE=0 NCCL_IB_CUDA_SUPPORT=1 NCCL_DMABUF_ENABLE=1 NCCL_GDR_LEVEL=PHB NCCL_IB_HCA=mlx5_2 $CMD"
                                fi
				if [ "$RANK" -eq 0 ]; then
					LOGFILE="$LOGDIR/$TYPE/stdout_nnodes${NODES}_nprocs${NPROC_PER_NODE}_numiter${NUM_ITER}_gradaccum${GRAD_ACCUM}_bs${BS}_seq${SEQ_LEN}_totalbs${TOTAL_BATCH_SIZE}_x4mtu${MTU_X4}_x8mtu${MTU_X8}.log"
					ssh cloud-user@$NODEIP "ulimit -n 65535 && source llmc/bin/activate && env && nstat --reset > /dev/null && echo \"=======Writing nstate pre data=======\" && nstat && cd llm.c && $CMD && echo \"=======Writing nstate post data=======\" && nstat" >> $LOGFILE
				else
					ssh -f cloud-user@$NODEIP "ulimit -n 65535 && source llmc/bin/activate && cd llm.c &&  $CMD > /tmp/trainlog"  
				fi
			done
			sleep 5
		done
		done
	done
done
