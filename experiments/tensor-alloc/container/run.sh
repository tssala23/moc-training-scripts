#!/bin/bash

set -uex

N_low=$1
N_high=$2

echo "Hostname:", $HOSTNAME
export MASTER_ADDR=torchrun-multipod-0.torchrun-multipod
export MASTER_PORT=29500
export NODE_RANK=$(hostname | awk -F'-' '{print $NF}')

torchrun --nnodes=2 --nproc-per-node=4 --node-rank=${NODE_RANK} --master-addr=${MASTER_ADDR} --master-port=${MASTER_PORT} torchrun_test.py ${N_low} ${N_high}

sleep infinity
