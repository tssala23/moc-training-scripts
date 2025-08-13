#!/bin/bash

ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -q 1 --use_cuda=0 --use_cuda_dmabuf -p 18515 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -q 1 --use_cuda=1 --use_cuda_dmabuf -p 18516 &
#ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -q 1 --use_cuda=2 --use_cuda_dmabuf -p 18517 &
#ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -q 1 --use_cuda=3 --use_cuda_dmabuf -p 18518 &
wait

