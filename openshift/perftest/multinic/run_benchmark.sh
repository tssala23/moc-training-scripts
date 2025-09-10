#!/bin/bash

typeset -r ts=$(date +%d-%m-%y-%s)

MTU=9000
PORTS=("18515" "18516" "18517" "18518")
QPAIRS=6
GPUS=4
INTERFACES=("eno5np0" "eno6np0" "eno7np0" "eno8np0")
HOST_NICS=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
CLIENT_NICS=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")  # Default: same as host NICs
HOST_IPS=("" "" "" "")
PODS=("sr4n1" "sr4n2")
BENCHMARKS=("ib_read_bw" "ib_write_bw" "ib_read_lat" "ib_write_lat")
FLAGS_BASE="-a -R -T 41 -F -x 3 -m 4096 --report_gbits "

function usage() 
{
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help      	Display this help message"
 echo " -p, --ports		Comma separated port list"
 echo " -n, --pods      	Comma separated pod list"
 echo " -i, --interfaces      	Comma separated interface (e.g. eno*)  list"
 echo " -m, --host-nics      	Comma separated host mellanox device (e.g. mlxn*) list"
 echo " -c, --client-nics     	Comma separated client mellanox device (e.g. mlxn*) list"
 echo " -b, --benchmarks     	Comma separated benchmark list"
 echo " -f, --flags      	Flags string base"
}

function hasarg() 
{
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

function extractarg() 
{
  echo "${2:-${1#*=}}"
}

function handleopts() 
{
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -n | --pods*)
        if ! hasarg $@; then
          echo "Pods not specified." >&2
          usage
          exit 1
        fi
        tmp=$(extractarg $@)
        IFS=','; PODS=($tmp); unset IFS;
        shift
        ;;
      -i | --interfaces*)
        if ! hasarg $@; then
          echo "Interfaces not specified." >&2
          usage
          exit 1
        fi
        tmp=$(extractarg $@)
        IFS=','; INTERFACES=($tmp); unset IFS;
        shift
        ;;
      -m | --host-nics*)
        if ! hasarg $@; then
          echo "Host NICS not specified." >&2
          usage
          exit 1
        fi
        tmp=$(extractarg $@)
        IFS=','; HOST_NICS=($tmp); unset IFS;
        shift
        ;;
      -c | --client-nics*)
        if ! hasarg $@; then
          echo "Client NICS not specified." >&2
          usage
          exit 1
        fi
        tmp=$(extractarg $@)
        IFS=','; CLIENT_NICS=($tmp); unset IFS;
        shift
        ;;
      -p | --ports*)
        if ! hasarg $@; then
          echo "Ports not specified." >&2
          usage
          exit 1
        fi
	tmp=$(extractarg $@)
	IFS=',';PORTS=($tmp); unset IFS;
	shift 
        ;;
      -b | --benchmarks*)
        if ! hasarg $@; then
          echo "Benchmarks not specified." >&2
          usage
          exit 1
        fi
	tmp=$(extractarg $@)
        IFS=',';BENCHMARKS=($tmp);unset IFS
        shift
        ;;
      -f | --flags*)
        if ! hasarg $@; then
          echo "Flags not specified." >&2
          usage
          exit 1
        fi
	tmp=$(extractarg $@)
	IFS=','; FLAGS_BASE=($tmp); unset IFS; 

        shift
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

function log()
{
    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG
}

HEXEC="oc exec"

LOGDIR="logs/run_${ts}"
CPULOGDIR="$LOGDIR/cpu"
GPULOGDIR="$LOGDIR/gpu"
mkdir -p $CPULOGDIR
mkdir -p $GPULOGDIR

function getips()
{
    h=$1
    c=$2
    for ((p=0; p<${#HOST_NICS[@]}; p++)); do
        HOST_IPS[$p]=`oc exec ${h} -- ifconfig | grep -A 1 ${INTERFACES[$p]} | grep -oE "inet \b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed -e "s/inet //"`
    done
}

function generate_nic_pattern()
{
    local pattern=""
    for ((i=0; i<${#HOST_NICS[@]}; i++)); do
        # Extract NIC numbers from device names (e.g., mlx5_2 -> 2)
        host_nic_num=$(echo ${HOST_NICS[$i]} | grep -o '[0-9]\+$')
        client_nic_num=$(echo ${CLIENT_NICS[$i]} | grep -o '[0-9]\+$')
        if [ -z "$pattern" ]; then
            pattern="H${host_nic_num}C${client_nic_num}"
        else
            pattern="${pattern}_H${host_nic_num}C${client_nic_num}"
        fi
    done
    echo $pattern
}

function execcmds()
{
    exlogbase=$2
    nic_pattern=$(generate_nic_pattern)

    for ((i=0; i<${#HOST_NICS[@]}; i++)); do
	d=${HOST_NICS[$i]}
	p=${PORTS[$i]}
	logfile="${exlogbase}_${nic_pattern}_${d}_${p}_host.log"
        host_cmd="${1} -d $d -p $p & 2&> ${logfile}"
        echo "Host is $host_cmd"
    done # Get all the hosts running first
    for ((i=0; i<${#CLIENT_NICS[@]}; i++)); do
	d=${CLIENT_NICS[$i]}
	p=${PORTS[$i]}
	h=${HOST_IPS[$i]}
	logfile="${exlogbase}_${nic_pattern}_${d}_${p}_${h}_client.log"
        client_cmd="${1} -d $d -p $p $h & 2&> ${logfile}"
        echo "Client is $client_cmd"
    done
	wait
}

function runbm()
{
    BM_OP=$1
    INCLUDE_QPS=0

    USE_GPU=$2
    getips $3 $4

    if  [ "$BM_OP" == "ib_read_bw" ] || [ "$BM_OP" == "ib_write_bw" ]; then 
        INCLUDE_QPS=1
    fi

    cmd_base="${BM_OP} ${FLAGS_BASE}"

    log_base="${LOGDIR}/"
    LOGFILE="${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
    
    if [ $INCLUDE_QPS == 1 ]; then
        for ((qp=0; qp<$QPAIRS; qp++)); do
	    qpair=$((2**qp))
	    ex_cmd_base="${cmd_base} -q ${qpair}"
	    if [ $USE_GPU == 1 ]; then
	        for ((g=0; g<$GPUS; g++)); do
	    	    logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${QP}"
                    ex_cmd_base="${cmd_base} -q ${qpair} --use_cuda=${g} --use_cuda_dmabuf"
	      	    execcmds $ex_cmd_base $logfile base 
      		done
	    else
	      logfilebase="${log_base}perftest_${BM_OP}_${MTU}_${QP}"
	      execcmds $ex_cmd_base $logfilebase
	    fi
	    
	done
    else
	if [ $USE_GPU == 1 ]; then
	        for ((g=0; g<$GPUS; g++)); do
		    logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${QP}"
                    ex_cmd_base="${cmd_base} --use_cuda=${g} --use_cuda_dmabuf"
	      	    execcmds $ex_cmd_base $logfilebase 
		done
	else
	      logfilebase="${log_base}perftest_${BM_OP}_${MTU}_${QP}"
	      execcmds $cmd_base $logfilebase 
        fi
    fi
}

handleopts "$@"

HOST=${PODS[0]}
CLIENT=${PODS[1]}

IPRF_LOG="${LOGDIR}/cpu/bmperf.log"
log "Pods to be tested for cpu rdma:  ${PODS[@]}"
for i in ${BENCHMARKS[@]}; do
    runbm $i 0 $HOST $CLIENT
done

IPRF_LOG="${LOGDIR}/gpu/bmperf.log"
log "Pods to be tested for gpu rdma:  ${PODS[@]}"
for i in ${BENCHMARKSS[@]}; do
    runbm $i 1 $HOST $CLIENT
done

