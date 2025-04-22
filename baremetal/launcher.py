#!/bin/bash

set -ue

log_loc=/home/fedora/experiments/logs

for num_iters in 10  #$(seq 10 10 30)
do
    for grad_accum in $(seq 1 1 10)
    do
        total_batch_size=$(($grad_accum*262144))
        log_file=$log_loc/prof_numiter$num_iters\_gradaccum$grad_accum\_bs32_seq1024_totalbs${total_batch_size}.nsys-rep

        echo $num_iters, $grad_accum
        ./run_exp.sh $num_iters $grad_accum 1 &
        ssh fedora@192.168.59.58 -i ~/.ssh/cross_connect 'bash -s' < ./run_exp.sh $num_iters $grad_accum 0
    done
done
