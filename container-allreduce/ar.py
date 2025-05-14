import torch
import torch.distributed as dist
import os
import numpy as np

def ar_test(size, niter=10, warmup=5):
    data = torch.randn(size, dtype=torch.float32).to(device)
    res = []

    #warmup
    for _ in range(warmup):
        dist.all_reduce(data, op=dist.ReduceOp.AVG, async_op=False)
        torch.cuda.synchronize()

    for i in range(niter):
        #use gpu stream events instead of cpu counters for timing
        start_time = torch.cuda.Event(enable_timing=True)
        end_time = torch.cuda.Event(enable_timing=True)

        #torch.cuda.synchronize()
        start_time.record()
        dist.all_reduce(data, op=dist.ReduceOp.AVG, async_op=False)
        #torch.cuda.synchronize() #we are using synchronous all-reduce but being safe
        end_time.record()

        torch.cuda.synchronize() #end.record() is on cuda stream

        time_ms = start_time.elapsed_time(end_time)
        data_amount_bytes = size * data.element_size()
        bps = data_amount_bytes/time_ms
    
        res.append((time_ms, data_amount_bytes, bps))
    
    return res

if __name__=='__main__':
    dist.init_process_group(backend='nccl')
    
    rank = dist.get_rank()
    local_rank = int(os.environ["LOCAL_RANK"])
    world_size = dist.get_world_size()
    
    device = f'cuda:{local_rank}'
    print(f'Rank {rank} World size {world_size}')

    for mb_size in [1, 4, 8, 16, 24, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]:
        res = ar_test(mb_size*1024*1024//4, niter=20, warmup=5)
        for i, (time_ms, data_amount_bytes, bps) in enumerate(res):
            print(f'RANK {rank} : Iter {i} : Size {mb_size} MB : Time {time_ms} ms : Data Amount {data_amount_bytes} bytes : bytes_per_ms {bps} : Gbps {(data_amount_bytes * 8 * 1000) / (1024*1024*1024) / time_ms} Gbps')

    dist.destroy_process_group()

