### Description

Disclaimer: There'll be further cleanup of the scripts etc. They are hacky right now.

The container files and yaml files are also included here.

#### Basic experiment

```    
num_iter = 10
for N in [1000, 10_000, 30_000]:
    start = time.time()
    for _ in range(num_iter):
        x = torch.randn((N, N), dtype=torch.float32).to(device)
        dist.all_reduce(x, op=dist.ReduceOp.AVG, async_op=False)
    end = time.time()
```

Goal: To measure time taken for all-reduce as a function of payload size. These experiments are running on two pods. Each pod is separated on a separate node with 4 GPUs each for a total of 8 workers.
