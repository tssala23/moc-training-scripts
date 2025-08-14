LOG_FILE="launch_chunked_0.csv"
if [ ! -f "$LOG_FILE" ]; then
    echo "start_time,end_time" > "$LOG_FILE"
fi
START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "\"$START_TIME\"," >> "$LOG_FILE"
model="ibm-granite/granite-3.3-8b-instruct"
CUDA_VISIBLE_DEVICES=0 python3 \
    -m vllm.entrypoints.openai.api_server \
    --model $model \
    --port 8100 \
    --max-model-len 10000 \
    --enable-chunked-prefill \
    --gpu-memory-utilization 0.6
END_TIME=$(date +"%Y-%m-%d %H:%M:%S")
sed -i "\$ s/$/\"$END_TIME\"/" "$LOG_FILE"
