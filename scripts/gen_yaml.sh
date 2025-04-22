#!/bin/bash
#TEMPLATE=template-batch-multiple-pod-torchrun.yaml
#LOC=yamls

TEMPLATE=template-nsys-batch-multiple-pod-torchrun.yaml
LOC=yamls/profile/run2

#TEMPLATE
#LOC=

ARG_PROFILE=1
ARG_MODEL=d12
ARG_RUNID=2

if [ ! -f $LOC ]
then
	mkdir -p $LOC
fi
 
for ARG_GRAD_ACCUM in $(seq 1 1 10)
do
	#sed s:ARG_NUM_PODS:1:g $TEMPLATE | sed s:ARG_NUM_PROC:8:g | sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g > $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}.yaml #will not work since no resources/nodes with 8 GPUs

	ARG_NUM_PODS=2
	ARG_NUM_PROC=4
	sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | sed s:ARG_NUM_PROC:$ARG_NUM_PROC:g | sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g | sed s:ARG_PROFILE:$ARG_PROFILE:g | sed s:ARG_MODEL:$ARG_MODEL:g | sed s:ARG_RUNID:$ARG_RUNID:g > $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}_profile${ARG_PROFILE}_model${ARG_MODEL}_runid${ARG_RUNID}.yaml

        ARG_NUM_PODS=4
        ARG_NUM_PROC=2
        sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | sed s:ARG_NUM_PROC:$ARG_NUM_PROC:g | sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g | sed s:ARG_PROFILE:$ARG_PROFILE:g | sed s:ARG_MODEL:$ARG_MODEL:g | sed s:ARG_RUNID:$ARG_RUNID:g > $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}_profile${ARG_PROFILE}_model${ARG_MODEL}_runid${ARG_RUNID}.yaml
	

        ARG_NUM_PODS=8
        ARG_NUM_PROC=1
        sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | sed s:ARG_NUM_PROC:$ARG_NUM_PROC:g | sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g | sed s:ARG_PROFILE:$ARG_PROFILE:g | sed s:ARG_MODEL:$ARG_MODEL:g | sed s:ARG_RUNID:$ARG_RUNID:g > $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}_profile${ARG_PROFILE}_model${ARG_MODEL}_runid${ARG_RUNID}.yaml

        ARG_NUM_PODS=1
	ARG_NUM_PROC=4
	sed s:ARG_NUM_PODS:$ARG_NUM_PODS:g $TEMPLATE | sed s:ARG_NUM_PROC:$ARG_NUM_PROC:g | sed s:ARG_GRAD_ACCUM:$ARG_GRAD_ACCUM:g | sed s:ARG_PROFILE:$ARG_PROFILE:g | sed s:ARG_MODEL:$ARG_MODEL:g | sed s:ARG_RUNID:$ARG_RUNID:g > $LOC/multipod-torchrun-pods${ARG_NUM_PODS}-procs${ARG_NUM_PROC}-grad${ARG_GRAD_ACCUM}_profile${ARG_PROFILE}_model${ARG_MODEL}_runid${ARG_RUNID}.yaml

done
