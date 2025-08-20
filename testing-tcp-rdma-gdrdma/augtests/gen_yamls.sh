#!/bin/bash

set -ueo pipefail

TEMPLATE=template-hostnetwork.yaml
ARG_PROFILE=0
ARG_MODEL=d12
ARG_NUM_PROCS=4
ARG_RUNID=aug15-gdr-valid


./scripts/gen_specific_yaml.sh $TEMPLATE \
	$ARG_PROFILE \
	$ARG_MODEL \
	$ARG_RUNID \
	$ARG_NUM_PROCS \

exit

TEMPLATE=template-multus.yaml
ARG_PROFILE=0
ARG_MODEL=d12
ARG_NUM_PROCS=4
ARG_NCCL_SOCKET_NTHREADS=16
ARG_NCCL_NSOCKS_PERTHREAD=4
ARG_RUNID=aug7multinicscan_multus_profile${ARG_PROFILE}_${ARG_MODEL}_ncclthreads${ARG_NCCL_SOCKET_NTHREADS}_ncclsocks${ARG_NCCL_NSOCKS_PERTHREAD}

./scripts/gen_specific_yaml.sh $TEMPLATE \
        $ARG_PROFILE \
        $ARG_MODEL \
        $ARG_RUNID \
        $ARG_NUM_PROCS \
        $ARG_NCCL_SOCKET_NTHREADS \
        $ARG_NCCL_NSOCKS_PERTHREAD

