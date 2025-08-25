PROFILE="${1:-profiles/default}"
[ -f "$PROFILE" ] && echo "Profile: $PROFILE " || { echo "Profile $PROFILE not found - exiting"; exit 1; }

DATA=$(yq .  "$PROFILE")

MODEL=$(jq -r '.vllm.model // ""' <<< "$DATA")
VLLM_USE_V1=$(jq -r '.vllm.use_v1 // ""' <<< "$DATA")
VLLM_PORT=$(jq -r '.vllm.port // ""' <<< "$DATA")
VLLM_MAX_MODEL_LEN=$(jq -r '.vllm.max_model_len // ""' <<< "$DATA")
VLLM_GPU_MEM_UTIL=$(jq -r '.vllm.gpu_mem_util // ""' <<< "$DATA")

if [ -z "$MODEL" ]; then
        echo "Model undefined - exiting"
        exit 1
fi


KV_IP=$(jq -r '.vllm.kv_ip // ""' <<< "$DATA")
KV_PORT=$(jq -r '.vllm.kv_port // "" '  <<< "$DATA")
KV_CONNECTOR=$(jq -r '.vllm.kv_connector // ""' <<< "$DATA")
KV_BUFFER_SIZE=$(jq -r '.vllm.kv_buffer_size // "" '  <<< "$DATA")
KV_ROLE=$(jq -r '.vllm.kv_role // ""' <<< "$DATA")
KV_RANK=$(jq -r '.vllm.kv_rank // ""' <<< "$DATA")
if [ -z "$KV_ROLE" ]; then
	echo "KV role undefined - exiting"
	exit 1
fi
if [ -z "$KV_RANK" ]; then
        echo "KV rank undefined - exiting"
        exit 1
fi

LOGDIR=$(jq -r '.log.output.logdir // "/tmp"' <<< "$DATA")
LOGFILE=$(jq -r '.log.output.filename // ("vllm_distributed")' <<< "$DATA")
LOGCMD=$(jq -r '.log.output.cmd // ""' <<< "$DATA")
NCCL_DEBUG=$(jq -r '.log.nccl.debug // ""' <<< "$DATA")
NCCL_DEBUG_SUBSYS=""
for KEY in $(jq -r '.log.nccl.subsys[] // ""' <<< "$DATA"); do
    NCCL_DEBUG_SUBSYS="${NCCL_DEBUG_SUBSYS},${KEY}"
done
if [ -n "$NCCL_DEBUG_SUBSYS" ]; then
    NCCL_DEBUG_SUBSYS="${NCCL_DEBUG_SUBSYS:1}"
fi
NCCL_TOPO_DUMP_FILE=$(jq -r '.log.nccl.topo // ""' <<< "$DATA")


PROFILE_PRERUN=$(jq -r '.profile.prerun // ""' <<< "$DATA")
PROFILE_POSTRUN=$(jq -r '.profile.postrun // ""' <<< "$DATA")
PROFILE_INLINE=$(jq -r '.profile.inline // ""' <<< "$DATA")


CUDA_VISIBLE_DEVICES=$(jq -r '.hw.gpu // 0' <<< "$DATA")
DEFAULT_IFNAME=$(jq -r '.ip.defaults.ifname // "eno"' <<< "$DATA")
DEFAULT_HCA=$(jq -r '.ip.defaults.hca // "mlx"' <<< "$DATA")
GPU_LABEL="gpu_${CUDA_VISIBLE_DEVICES}"
GPU_NIC_NAME=$(jq -r --arg gpu "$GPU_LABEL" --arg def "$DEFAULT_IFNAME" '.ip.data[$gpu].name // "$def"' <<< "$DATA")
GPU_HCA_NAME=$(jq -r --arg gpu "$GPU_LABEL" --arg def "$DEFAULT_HCA" '.ip.data[$gpu].hca // "$def"' <<< "$DATA")


NCCL_IB_DISABLE=$(jq -r '.nccl.NCCL_IB_DISABLE // 0' <<< "$DATA")
NCCL_IB_OOB_IPV6_DISABLE=$(jq -r '.nccl.NCCL_IB_OOB_IPV6_DISABLE // ""' <<< "$DATA")
NCCL_SOCKET_NTHREADS=$(jq -r '.nccl.NCCL_SOCKET_NTHREADS // ""' <<< "$DATA")
NCCL_NSOCKS_PERTHREAD=$(jq -r '.nccl.NCCL_NSOCKS_PERTHREAD // ""' <<< "$DATA")
NCCL_DMABUF_ENABLE=$(jq -r '.nccl.NCCL_DMABUF_ENABLE // ""' <<< "$DATA")
NCCL_GDR_LEVEL=$(jq -r '.nccl.NCCL_GDR_LEVEL // ""' <<< "$DATA")
NCCL_NET_GDR_READ=$(jq -r '.nccl.NCCL_NET_GDR_READ // ""' <<< "$DATA")
NCCL_IB_GID_INDEX=$(jq -r '.nccl.NCCL_IB_GID_INDEX // ""' <<< "$DATA")
NCCL_IB_HCA=""
NCCL_SOCKET_IFNAME=""
GLOO_SOCKET_IFNAME=""

for IFACE_KEY in $(jq -r '.hardware.nics.control[] // ""' <<< "$DATA"); do
    IFACE_NAME=$(jq -r --arg key "$IFACE_KEY" '.ip.control[$key].name // ""' <<< "$DATA")
    if [ -n "$IFACE_NAME" ]; then
	NCCL_SOCKET_IFNAME="${NCCL_SOCKET_IFNAME},${IFACE_NAME}"
    fi
    IFACE_NAME=$(jq -r --arg key "$IFACE_KEY" '.ip.data[$key].name // ""' <<< "$DATA")
    if [ -n "$IFACE_NAME" ]; then
        NCCL_SOCKET_IFNAME="${NCCL_SOCKET_IFNAME},${IFACE_NAME}"
    fi
done
if [ -z "$NCCL_SOCKET_IFNAME" ]; then
    NCCL_SOCKET_IFNAME=$DEFAULT_IFNAME
else
    NCCL_SOCKET_IFNAME="${NCCL_SOCKET_IFNAME:1}"
fi
GLOO_SOCKET_IFNAME=$NCCL_SOCKET_IFNAME


if [[ "$NCCL_IB_DISABLE" -eq 0 ]]; then
	NCCL_IB_HCA=""
	for IFACE_KEY in $(jq -r '.hardware.nics.data[] // ""' <<< "$DATA"); do
   		IFACE_NAME=$(jq -r --arg key "$IFACE_KEY" '.ip.control[$key].name // ""' <<< "$DATA")
   		if [ -n "$IFACE_NAME" ]; then
        		NCCL_IB_HCA="${NCCL_IB_HCA},${IFACE_NAME}"
   		fi
    		IFACE_NAME=$(jq -r --arg key "$IFACE_KEY" '.ip.data[$key].name // ""' <<< "$DATA")
    		if [ -n "$IFACE_NAME" ]; then
        		NCCL_IB_HCA="${NCCL_IB_HCA},${IFACE_NAME}"
    		fi
	done
	if [ -z "$NCCL_IB_HCA" ]; then
    		NCCL_IB_HCA=$GPU_IFNAME  # defaulting to the selected gpu hca name
	else
    		NCCL_IB_HCA="${NCCL_IB_HCA:1}"
	fi
fi

# Build file contents and generate run.sh

param() { [ -n "$2" ] && echo "$1=$2 "; }

CMD=''
CMD+='TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")''\n'
CMD+=$([ -n "$LOGCMD" ] && echo 'mkdir -p '$LOGDIR' ''\n')
CMD+='if [ ! -f "'${GPU_LABEL}'_usage.csv" ]; then''\n'
CMD+='\techo "start_time,end_time" > "'${GPU_LABEL}'_usage.csv"''\n'
CMD+='fi''\n'
CMD+='START_TIME=$(date +"%Y-%m-%d %H:%M:%S")''\n'
CMD+='echo "\\"$START_TIME\\"," >> "'${GPU_LABEL}'_usage.csv"''\n'

if [ -n "$PROFILE_PRERUN" ]; then
    CMD+="${PROFILE_PRERUN}"'\n'
fi

CMD+=$(param VLLM_USE_V1 "$VLLM_USE_V1")
CMD+=$(param CUDA_VISIBLE_DEVICES "$CUDA_VISIBLE_DEVICES")
CMD+=$(param NCCL_DEBUG "$NCCL_DEBUG")
CMD+=$(param NCCL_DEBUG_SUBSYS "$NCCL_DEBUG_SUBSYS")
CMD+=$(param NCCL_IB_DISABLE "$NCCL_IB_DISABLE")
CMD+=$(param NCCL_IB_OOB_IPV6_DISABLE "$NCCL_IB_OOB_IPV6_DISABLE")
CMD+=$(param NCCL_SOCKET_NTHREADS "$NCCL_SOCKET_NTHREADS")
CMD+=$(param NCCL_NSOCKS_PERTHREAD "$NCCL_NSOCKS_PERTHREAD")
CMD+=$(param NCCL_DMABUF_ENABLE "$NCCL_DMABUF_ENABLE")
CMD+=$(param NCCL_GDR_LEVEL "$NCCL_GDR_LEVEL")
CMD+=$(param NCCL_IB_GID_INDEX "$NCCL_IB_GID_INDEX")
CMD+=$(param NCCL_IB_HCA "$NCCL_IB_HCA")
CMD+=$(param NCCL_TOPO_DUMP_FILE "$NCCL_TOPO_DUMP_FILE")
CMD+=$(param NCCL_SOCKET_IFNAME "$NCCL_SOCKET_IFNAME")
CMD+=$(param GLOO_SOCKET_IFNAME "$GLOO_SOCKET_IFNAME")

if [ -n "$PROFILE_INLINE" ]; then
    CMD+="${PROFILE_INLINE} "
fi

CMD+='python3 \ ''\n'
CMD+=' -m vllm.entrypoints.openai.api_server \ ''\n'
CMD+=' --model '$MODEL' \ ''\n'
CMD+=$([ -n "$VLLM_PORT" ] && echo ' --port '$VLLM_PORT' \ ''\n')
CMD+=$([ -n "$VLLM_MAX_MODEL_LEN" ] && echo ' --max-model-len '$VLLM_MAX_MODEL_LEN' \ ''\n')
CMD+=$([ -n "$VLLM_GPU_MEM_UTIL" ] && echo ' --gpu-memory-utilization '$VLLM_GPU_MEM_UTIL' \ ''\n')
CMD+=' --kv-transfer-config \ ''\n'
CMD+=' {"kv_role":"'$KV_ROLE'"'
CMD+=$([ -n "$KV_CONNECTOR" ] && echo ', "kv_connector":"'$KV_CONNECTOR'"')
CMD+=$([ -n "$KV_RANK" ] && echo ', "kv_rank":'$KV_RANK)
CMD+=$([ -n "$KV_IP" ] && echo ', "kv_ip":"'$KV_IP'"')
CMD+=$([ -n "$KV_PORT" ] && echo ', "kv_port":'$KV_PORT)
CMD+=$([ -n "$KV_BUFFER_SIZE" ] && echo ', "kv_buffer_size":'$KV_BUFFER_SIZE)
CMD+='} '

if [ -n "$LOGCMD" ]; then
    CMD+="  ${LOGCMD}  ${LOGDIR}/${LOGFILE}"'\n'
fi

CMD+='\n'

if [ -n "$PROFILE_POSTRUN" ]; then
    CMD+="${PROFILE_POSTRUN}"'\n'
fi

CMD+='END_TIME=$(date +"%Y-%m-%d %H:%M:%S")''\n'
CMD+='sed -i "\$ s/$/\"$END_TIME\"/" "'${GPU_LABEL}'_usage.csv"'

echo  -e $CMD  > run.sh 
