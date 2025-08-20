#!/bin/bash

set -ueo pipefail

TEMPLATE=${1:-template-hostnetwork.yaml}

ARG_PROFILE=${2:-0}
ARG_MODEL=${3:-d12}
ARG_RUNID=${4:-jul31multinicscan}
ARG_NUM_PROCS=${5:-4}
LOC=${6:-yamls_host/$ARG_RUNID}

if [ ! -f $LOC ]
then
	mkdir -p $LOC
fi

POD_LIST=(1 2 3 4 5 6 7 8)
NIC_LIST=(1 2 3 4)
TYPE_LIST=(TCP RDMA GDRNOREAD GDRWITHREAD)
BUCKET_LIST=(25) #(5 10 15 20 25 50 75 100 125 150 200 250 300 400 500 1000 2000 5000 10000)
NCCL_SOCKET_NTHREADS_LIST=(4) #(1 2 4 8 16 32 64)
NCCL_NSOCKS_PERTHREAD_LIST=(1) #( 1 2 4 8 16 32 64)

for ARG_NUM_PODS in ${POD_LIST[@]}
do
	for ARG_NUM_NICS in ${NIC_LIST[@]}
	do
		for ARG_TYPE in ${TYPE_LIST[@]}
		do
			for ARG_BUCKET_CAP in ${BUCKET_LIST[@]}
			do

				for ARG_NCCL_SOCKET_NTHREADS in ${NCCL_SOCKET_NTHREADS_LIST[@]}
				do
				
				        for ARG_NCCL_NSOCKS_PERTHREAD in ${NCCL_NSOCKS_PERTHREAD_LIST[@]}
				        do
                				prod=$(($ARG_NCCL_SOCKET_NTHREADS * $ARG_NCCL_NSOCKS_PERTHREAD))
				                if [ $prod -gt 64 ]
				                then
				                        echo "Skipping: NCCL_SOCKET_NTHREADS=$ARG_NCCL_SOCKET_NTHREADS NCCL_NSOCKS_PERTHREAD=$ARG_NCCL_NSOCKS_PERTHREAD"
				                        continue
				                fi
                				echo "NCCL_SOCKET_NTHREADS=$ARG_NCCL_SOCKET_NTHREADS NCCL_NSOCKS_PERTHREAD=$ARG_NCCL_NSOCKS_PERTHREAD"
			
						sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | \
							sed s:ARG_NUM_PROCS:$ARG_NUM_PROCS:g | \
							sed s:ARG_PROFILE:$ARG_PROFILE:g | \
							sed s:ARG_TYPE:$ARG_TYPE:g | \
							sed s:ARG_NUM_NICS:$ARG_NUM_NICS:g | \
							sed s:ARG_RUNID:$ARG_RUNID:g | \
							sed s:ARG_NCCL_SOCKET_NTHREADS:$ARG_NCCL_SOCKET_NTHREADS:g | \
							sed s:ARG_NCCL_NSOCKS_PERTHREAD:$ARG_NCCL_NSOCKS_PERTHREAD:g | \
							sed s:ARG_BUCKET_CAP:$ARG_BUCKET_CAP:g \
								> $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROCS}-nic${ARG_NUM_NICS}-profile${ARG_PROFILE}-model${ARG_MODEL}-type${ARG_TYPE}-ncclnthreads${ARG_NCCL_SOCKET_NTHREADS}-ncclnsocks${ARG_NCCL_NSOCKS_PERTHREAD}-bucketcap${ARG_BUCKET_CAP}-runid${ARG_RUNID}.yaml
		
					done
				done
			done
		done
	done
done


