###

This is an attempt at using host networking i.e. using passthrough to allocate all the hosts networking resources to the single pod running on the node.

We are using device mlx5_2 and its exposed interface (/sys/class/infiniband/mlx5_2/device/net/eno6np0). This interface needs to have an IPv4 address assigned which is done in roce-nsys-container/run.sh.

Commands used for ib_write:

Server:
ib_write_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1

Client:
ib_write_bw -a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d mlx5_2 -q 1 192.168.90.101

where the ip is from ip addr show eno6np0

Next steps:
- use gpu direct (use_cuda, use_dmabuf)
- nstat + nsys
