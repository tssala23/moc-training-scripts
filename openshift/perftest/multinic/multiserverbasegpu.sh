#!/bin/bash

ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -p 18515 --run_infinitely --use_cuda=0 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -p 18516 --run_infinitely --use_cuda=1 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -p 18517 --run_infinitely --use_cuda=2 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -p 18518 --run_infinitely --use_cuda=3 --use_cuda_dmabuf &
wait

ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -q 1 -p 18515 --run_infinitely --use_cuda=0 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -q 1 -p 18516 --run_infinitely --use_cuda=1 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -q 1 -p 18517 --run_infinitely --use_cuda=2 --use_cuda_dmabuf &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -q 1 -p 18518 --run_infinitely --use_cuda=3 --use_cuda_dmabuf &
wait

