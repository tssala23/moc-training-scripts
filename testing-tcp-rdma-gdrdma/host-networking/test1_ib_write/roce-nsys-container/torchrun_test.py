import os
import torch.distributed as dist
import torch

if __name__=='__main__':
    dist.init_process_group(backend='nccl')
    rank = dist.get_rank()
    world_size = dist.get_world_size()

    rank = int(os.environ["RANK"])
    world_size = int(os.environ["WORLD_SIZE"])
    local_rank = int(os.environ["LOCAL_RANK"])

    print(f'Rank {rank} Local rank {local_rank} World size {world_size}')

    torch.cuda.set_device(local_rank)
    device = torch.device("cuda", local_rank)
    x = torch.randn((3,5)).to(device)

    print(x)

    dist.all_reduce(x, op=dist.ReduceOp.SUM)

    print(x)

    dist.destroy_process_group()
