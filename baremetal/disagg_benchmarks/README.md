## Benchmark flow

### Chunked Prefill
launch_chunked_0.sh -> launch_chunked_1.sh -> launch_chunked_roundrobin.sh -> launch_chunked.sh

### Disagg Prefill
launch_disagg_0.sh -> launch_disagg_1.sh -> launch_disagg_proxyserver.sh -> launch_disagg.sh

### Plot
python term_plot.py
