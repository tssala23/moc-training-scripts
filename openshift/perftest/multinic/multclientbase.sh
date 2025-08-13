#!/bin/bash

ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -p 18515 --run_infinitely 192.168.101.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -p 18516 --run_infinitely 192.168.100.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -p 18517 --run_infinitely 192.168.103.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -p 18518 --run_infinitely 192.168.102.93 &
wait

ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_2 -q 1 -p 18515 --run_infinitely 192.168.101.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_3 -q 1 -p 18516 --run_infinitely 192.168.100.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_4 -q 1 -p 18517 --run_infinitely 192.168.103.93 &
ib_read_bw -R -T 41 -F -x 3 -m 4096  --report_gbits -d mlx5_5 -q 1 -p 18518 --run_infinitely 192.168.102.93 &
wait

