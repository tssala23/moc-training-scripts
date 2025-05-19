#!/bin/bash

TEMPLATE=template-multipod-train-novolume.yaml

ARG_PROFILE=0
ARG_MODEL=d12
ARG_RUNID=may18_protoscan
LOC=yamls/$ARG_RUNID

ARG_NUM_PODS=2
ARG_NUM_PROC=4

if [ ! -f $LOC ]
then
	mkdir -p $LOC
fi

for ARG_TYPE in TCP RDMA GDR
do
	for ARG_GRAD_ACCUM in $(seq 1 1 10)
	do
        	sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | \
			sed s:ARG_NUM_PROC:$ARG_NUM_PROC:g | \
			sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g | \
			sed s:ARG_PROFILE:$ARG_PROFILE:g | \
			sed s:ARG_MODEL:$ARG_MODEL:g | \
			sed s:ARG_RUNID:$ARG_RUNID:g | \
			sed s:ARG_TYPE:${ARG_TYPE}:g \
				> $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}_profile${ARG_PROFILE}_model${ARG_MODEL}_type${ARG_TYPE}_runid${ARG_RUNID}.yaml
	done
done
