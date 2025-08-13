#!/bin/bash

ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -q 1 -p 18515 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -q 1 -p 18516 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -q 1 -p 18517 &
ib_read_bw -a -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -q 1 -p 18518 &
wait

