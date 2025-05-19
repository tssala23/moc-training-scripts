import os
import torch
import torch.distributed as dist
import time
import csv

TYPE="tcp" # "rdma"  "gdrdma"

def run_allreduce(dbytes, device):
    num_elements = dbytes >> 2
    x = torch.randn(num_elements, dtype=torch.float32, device=device)
    for i in range(3):
        dist.all_reduce(x, op=dist.ReduceOp.SUM)
        torch.cuda.synchronize()
    runs = []
    for i in range(10):
        torch.cuda.synchronize()
        start = time.time()
        dist.all_reduce(x, op=dist.ReduceOp.SUM)
        torch.cuda.synchronize()
        end = time.time()
        runs.append(end - start)
    return runs


dist.init_process_group(backend='nccl')
rank = dist.get_rank()
world_size = dist.get_world_size()
rank = int(os.environ["RANK"])
world_size = int(os.environ["WORLD_SIZE"])
local_rank = int(os.environ["LOCAL_RANK"])

print(f'Rank {rank} Local rank {local_rank} World size {world_size}')

torch.cuda.set_device(local_rank)
device = torch.device("cuda", local_rank)

sizes = [2**x for x in range(27, 32 + 1)]
results = []

if rank == 0:
    print(f"{'Size (Bytes)':>12}  {'Avg BW (Gbps)':>15} {'Peak BW (Gbps)':>12}")

for size in sizes:
    result = run_allreduce(size, device)
    size_gbits = int((size*8)/(1024*1024*1024))
    all_bws = []
    for runtime in result:
        all_bws.append(size_gbits/runtime)
    avg_bw = sum(all_bws)/len(all_bws)
    peak_bw = max(all_bws)    
    if rank == 0:
        print(f"{size:12.2f} {avg_bw:15.2f} {peak_bw:12.2f}")
        results.append((TYPE,size,avg_bw,peak_bw))

if rank == 0:
    with open("results.csv", mode="w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Type", "Size (Bytes)", "Avg BW (Gbps)", "Peak BW (Gbps)"])
        writer.writerows(results)

dist.destroy_process_group()
