import os
import torch.distributed as dist
import sys
import torch
import time
import numpy as np

if __name__=='__main__':
    print("---------")
    print(sys.argv[1], sys.argv[2])
    N_low = int(sys.argv[1])
    N_high = int(sys.argv[2])

    dist.init_process_group(backend='nccl')
    rank = int(os.environ["RANK"])
    local_rank = int(os.environ["LOCAL_RANK"])
    world_size = int(os.environ["WORLD_SIZE"])
    

    print(f'Rank {rank} World size {world_size}')
    device = f'cuda:{local_rank}'
    
    #x = torch.randn((N, N)).to(device)
    ##x = torch.ones(10).to(device)
    
    #print(x)
    #dist.all_reduce(x, op=dist.ReduceOp.AVG, async_op=False)
    ##dist.all_reduce(x, op=dist.ReduceOp.SUM, async_op=False)
    
    ##print(x)

    num_iter = 10
    #for N in 10**np.arange(N_low, N_high+1):
    for N in [1000, 10_000, 30_000]:
        #x = torch.randn((N, N), dtype=torch.float32).to(device)
        start = time.time()
        for _ in range(num_iter):
            x = torch.randn((N, N), dtype=torch.float32).to(device)
            dist.all_reduce(x, op=dist.ReduceOp.AVG, async_op=False)
            #memalloc = torch.cuda.memory_allocated(device=device)
            #memstats = torch.cuda.memory_stats()
            #print(f"memalloc: {memalloc}")
            #print(f"memstats: {memstats}")
        end = time.time()

        total_time_ms = 1000*(end-start)
        print(f"Rank={rank} N={N:_} Nelem={N**2:_} TotalTime={total_time_ms:_}ms TimePerIter={total_time_ms/num_iter:.32f}ms")

    dist.destroy_process_group()
