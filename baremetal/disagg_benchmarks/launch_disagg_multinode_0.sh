LOG_FILE="launch_disagg_0.csv"
if [ ! -f "$LOG_FILE" ]; then
    echo "start_time,end_time" > "$LOG_FILE"
fi
START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "\"$START_TIME\"," >> "$LOG_FILE"
model="ibm-granite/granite-3.3-8b-instruct"
VLLM_USE_V1=0 CUDA_VISIBLE_DEVICES=0 NCCL_IB_OOB_IPV6_DISABLE=1 GLOO_SOCKET_IFNAME=eno2np0 NCCL_SOCKET_NTHREADS=16 NCCL_NSOCKS_PERTHREAD=4 NCCL_SOCKET_IFNAME=eno2np0 NCCL_DMABUF_ENABLE=1 NCCL_GDR_LEVEL=PHB NCCL_IB_HCA=mlx5_2,mlx5_3,mlx5_4,mlx5_5 python3 \
    -m vllm.entrypoints.openai.api_server \
    --model $model \
    --port 8100 \
    --max-model-len 10000 \
    --gpu-memory-utilization 0.6 \
    --kv-transfer-config \
    '{"kv_connector":"PyNcclConnector","kv_role":"kv_producer","kv_rank":0,"kv_parallel_size":2,"kv_buffer_size":5e9, "kv_ip":"192.168.50.182"}'
END_TIME=$(date +"%Y-%m-%d %H:%M:%S")
sed -i "\$ s/$/\"$END_TIME\"/" "$LOG_FILE"

