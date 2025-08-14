benchmark() {
  results_folder="./chunked_results"
  model="ibm-granite/granite-3.3-8b-instruct"
  dataset_name="sonnet"
  dataset_path="../sonnet_4x.txt"
  num_prompts=100
  qps=$1
  prefix_len=50
  input_len=1024
  output_len=$2
  tag=$3

  vllm bench serve \
    --backend vllm \
    --model $model \
    --dataset-name $dataset_name \
    --dataset-path $dataset_path \
    --sonnet-input-len $input_len \
    --sonnet-output-len "$output_len" \
    --sonnet-prefix-len $prefix_len \
    --num-prompts $num_prompts \
    --port 8000 \
    --save-result \
    --result-dir $results_folder \
    --result-filename "$tag"-qps-"$qps".json \
    --request-rate "$qps"

  sleep 2
}
main() {
  rm -rf chunked_results
  mkdir chunked_results
  default_output_len=6
  export VLLM_HOST_IP=$(hostname -I | awk '{print $1}')
  for qps in 2 4 6 8; do
  benchmark $qps $default_output_len chunked_prefill
  done
}
main "$@"

