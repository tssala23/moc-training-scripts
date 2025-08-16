LOG_FILE="launch_disagg_0.csv"
if [ ! -f "$LOG_FILE" ]; then
    echo "start_time,end_time" > "$LOG_FILE"
fi
START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "\"$START_TIME\"," >> "$LOG_FILE"
model="ibm-granite/granite-3.3-8b-instruct"
VLLM_USE_V1=0 CUDA_VISIBLE_DEVICES=0 NCCL_DEBUG=INFO NCCL_SUBSYS=INIT,NET,GRAPH,GDR nsys profile --trace=cuda,nvtx,osrt --gpu-metrics-devices=all --gpu-metrics-set=gh100 --output launch_disagg_w_profiler_0.nsys-rep python3 \
    -m vllm.entrypoints.openai.api_server \
    --model $model \
    --port 8100 \
    --max-model-len 10000 \
    --gpu-memory-utilization 0.6 \
    --kv-transfer-config \
    '{"kv_connector":"PyNcclConnector","kv_role":"kv_producer","kv_rank":0,"kv_parallel_size":2,"kv_buffer_size":5e9}' >> launch_disagg_w_profiler_0.log
END_TIME=$(date +"%Y-%m-%d %H:%M:%S")
sed -i "\$ s/$/\"$END_TIME\"/" "$LOG_FILE"

