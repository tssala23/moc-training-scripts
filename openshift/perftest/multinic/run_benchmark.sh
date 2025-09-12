#!/bin/bash

typeset -r ts=$(date +%d-%m-%y-%s)

MTU=9000
PORTS=("18515" "18516" "18517" "18518")
QPAIRS=5
GPUS=4
INTERFACES=("eno5np0" "eno6np0" "eno7np0" "eno8np0")
HOST_NICS=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
CLIENT_NICS=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")  # Default: same as host NICs
HOST_IPS=("" "" "" "")
PODS=("sr4n1" "sr4n2")
BENCHMARKS=("ib_read_bw" "ib_write_bw" "ib_read_lat")
FLAGS_BASE="-a -R -T 41 -F -x 3 -m 4096 --report_gbits "
DRY_RUN=0
AFFINITY_ONLY=0
AFFINITIES=(1 0 3 2)


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
 echo " -d, --dryrun      Print commands but don't run them"
 echo " -a, --affinity-only Only use optimal GPU-NIC affinity cases"
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
      -d | --dryrun)
        DRY_RUN=1
        ;;
      -a | --affinity-only)
        AFFINITY_ONLY=1
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
        HOST_IPS[$p]=`oc exec ${h} -- ifconfig 2> /dev/null | grep -A 1 ${INTERFACES[$p]} | grep -oE "inet \b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed -e "s/inet //"`
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
  podh=$3
  podc=$4
  runcmd=$1

  if [ $AFFINITY_ONLY == 1 ]; then
    for ((i=0; i<${#HOST_NICS[@]}; i++)); do
	    d=${HOST_NICS[$i]}
	    p=${PORTS[$i]}
	    logfile="${exlogbase}_${nic_pattern}_${d}_${p}_${h}_host.log"
      host_cmd="oc exec ${runcmd} -- ${podh} -d $d -p $p --use_cuda=${AFFINITIES[$i]} --use_cuda_dmabuf > ${logfile} 2>&1 &"
      if [ $DRY_RUN -eq 1 ]; then
        echo "Host command is $host_cmd"
      else
        eval "${host_cmd}"
      fi
    done # Get all hosts in place first
    for ((i=0; i<${#CLIENT_NICS[@]}; i++)); do
	    d=${CLIENT_NICS[$i]}
	    p=${PORTS[$i]}
	    logfile="${exlogbase}_${nic_pattern}_${d}_${p}_${h}_host.log"
      client_cmd="oc exec ${runcmd} -- ${podc} -d $d -p $p $h > ${logfile} 2>&1 &"
      if [ $DRY_RUN -eq 1 ]; then
        echo "Client command is $client_cmd"
      else
        eval "${host_cmd}"
      fi
    done
  else
    for ((i=0; i<${#HOST_NICS[@]}; i++)); do
	    d=${HOST_NICS[$i]}
	    p=${PORTS[$i]}
	    h=${HOST_IPS[$i]}
	    logfile="${exlogbase}_${nic_pattern}_${d}_${p}_${h}_host.log"
      host_cmd="oc exec ${podh} -- ${runcmd} -d $d -p $p > ${logfile} 2>&1 &"
      if [ $DRY_RUN -eq 1 ]; then
        echo "Host command is $host_cmd"
      else
        eval "${host_cmd}"
      fi
    done # Get all the hosts running first
    for ((i=0; i<${#CLIENT_NICS[@]}; i++)); do
	    d=${CLIENT_NICS[$i]}
	    p=${PORTS[$i]}
	    h=${HOST_IPS[$i]}
	    logfile="${exlogbase}_${nic_pattern}_${d}_${p}_${h}_client.log"
      client_cmd="oc exec ${podc} -- ${runcmd} -d $d -p $p $h > ${logfile} 2>&1 &"
      if [ $DRY_RUN -eq 1 ]; then
        echo "Client command is $client_cmd"
      else
        eval "${client_cmd}"
      fi
    done
  fi
	wait
}

function runbm()
{
  BM_OP=$1
  INCLUDE_QPS=0

  USE_GPU=$2
  ITER_HOST=$3
  ITER_CLI=$4

  getips $ITER_HOST $ITER_CLI

  if  [ "$BM_OP" == "ib_read_bw" ] || [ "$BM_OP" == "ib_write_bw" ]; then 
      INCLUDE_QPS=1
  fi

  cmd_base="${BM_OP} ${FLAGS_BASE}"

  log_base="${LOGDIR}/perftest"
# ADDBACK    LOGFILE="${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
# perftest_[gpu|cpu]_[srv|clt]_<TEST>_<MTU>_<QP>_<srvNode>_<clientNode>_<GPU_S>_<GPU_C>.log
  logfile_qps=

    if [ $INCLUDE_QPS == 1 ]; then
      for ((qp=0; qp<$QPAIRS; qp++)); do
        if [ $INCLUDE_QPS != 1 ]; then
          qp=$QPAIRS
#	        logfilebase="${log_base}perftest_${BM_OP}_${MTU}"
          ex_cmd_base="${cmd_base}"
        else
	        qpair=$((2**qp))
	        ex_cmd_base="${cmd_base} -q ${qpair}"
          logfile_qps="_${qpair}"
	    	  #logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${qpair}"
        fi
        if [ $AFFINITY_ONLY == 1 ]; then
	    	    logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${qpair}${qpair}"
	          execcmds "${ex_cmd_base}" "${logfilebase}" "${ITER_HOST}" "${ITER_CLI}"  
	      elif [ $USE_GPU == 1 ]; then
	        for ((g=0; g<$GPUS; g++)); do
	    	    logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}${qpair}"
            ex_cmd_base="${cmd_base} -q ${qpair} --use_cuda=${g} --use_cuda_dmabuf"
	          execcmds "${ex_cmd_base}" "${logfilebase}" "${ITER_HOST}" "${ITER_CLI}" 
      	  done
	      else
	          logfilebase="${log_base}perftest_cpu_${BM_OP}_${MTU}${qpair}"
	          execcmds "${ex_cmd_base}" "${logfilebase}" "${ITER_HOST}" "${ITER_CLI}"
	      fi 
	    done
    else
	    if [ $USE_GPU == 1 ]; then
	      for ((g=0; g<$GPUS; g++)); do
		      logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}${qpair}"
          ex_cmd_base="${cmd_base} --use_cuda=${g} --use_cuda_dmabuf"
	      	execcmds "${ex_cmd_base}" "${logfilebase}" "${ITER_HOST}" "${ITER_CLI}" 
		    done
	    else
	      logfilebase="${log_base}perftest_cpu_${BM_OP}_${MTU}${qpair}"
	      execcmds "${cmd_base}" "${logfilebase}" "${ITER_HOST}" "${ITER_CLI}"
      fi
    fi
}

handleopts "$@"
BM_USE_CPU=0
BM_USE_GPU=1

IPRF_LOG="${LOGDIR}/cpu/bmperf.log"
log "Pods to be tested for cpu rdma:  ${PODS[@]}"

for HOST in ${PODS[@]}; do
  for CLIENT in ${PODS[@]}; do
    if [ $HOST = $CLIENT ]; then
      continue
    fi
    for BENCH in ${BENCHMARKS[@]}; do
      runbm $BENCH $BM_USE_CPU $HOST $CLIENT
    done
  done
done

IPRF_LOG="${LOGDIR}/gpu/bmperf.log"
log "Pods to be tested for gpu rdma:  ${PODS[@]}"
for HOST in ${PODS[@]}; do
  for CLIENT in ${PODS[@]}; do
    if [ $HOST = $CLIENT ]; then
      continue
    fi
    for BENCH in ${BENCHMARKS[@]}; do
      runbm $BENCH $BM_USE_GPU $HOST $CLIENT
    done
  done
done