import os
import torch.distributed as dist

if __name__=='__main__':
    dist.init_process_group(backend='nccl')
    rank = dist.get_rank()
    world_size = dist.get_world_size()

    print(f'Rank {rank} World size {world_size}')
    dist.destroy_process_group()
