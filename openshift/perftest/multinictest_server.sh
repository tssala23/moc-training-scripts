#!/bin/bash

ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 &
wait


ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 --use_cuda=0 --use_cuda_dmabuf &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 --use_cuda=0 --use_cuda_dmabuf &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 --use_cuda=0 --use_cuda_dmabuf &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 --use_cuda=0 --use_cuda_dmabuf &
wait
