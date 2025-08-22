#!/bin/bash

typeset -r ts=$(date +%d-%m-%y-%s)

MTU=9000
PORTS=("18515" "18516" "18517" "18518")
QPAIRS=6
GPUS=4
IFS=("eno5np0" "eno6np0" "eno7np0" "eno8np0")
NICS=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
HOST_IPS=("" "" "" "")
PODS=("sr4n1" "sr4n2")   
BMS=("ib_read_bw" "ib_write_bw" "ib_read_lat" "ib_write_lat")
FLAGS_BASE="-a -R -T 41 -F -x 3 -m 4096 --report_gbits "

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
    for ((p=0; p<${#NICS[@]}; p++)); do
        HOST_IPS[$p]=`oc exec ${h} -- ifconfig | grep -A 1 ${IFS[$p]} | grep -oE "inet \b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed -e "s/inet //"`
    done
}

function execcmds()
{
    exlogbase=$2

    for ((i=0; i<${#NICS[@]}; i++)); do
	d=${NICS[$i]}
	p=${PORTS[$i]}
	logfile="${exlogbase}_${d}_${p}_host.log"
        host_cmd="${1} -d $d -p $p & 2&> ${logfile}"
        echo "Host is $host_cmd"
    done # Get all the hosts running first
    for ((i=0; i<${#NICS[@]}; i++)); do
	d=${NICS[$i]}
	p=${PORTS[$i]}
	h=${HOST_IPS[$i]}
	logfile="${exlogbase}_${d}_${p}_${h}_client.log"
        client_cmd="${1} -d $d -p $p $h & 2&> ${logfile}"
        echo "Client is $client_cmd"
    done
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

HOST=${PODS[0]}
CLIENT=${PODS[1]}

IPRF_LOG="${LOGDIR}/cpu/bmperf.log"
log "Pods to be tested for cpu rdma:  ${PODS[@]}"
for i in ${BMS[@]}; do
    runbm $i 0 $HOST $CLIENT
done

IPRF_LOG="${LOGDIR}/gpu/bmperf.log"
log "Pods to be tested for gpu rdma:  ${PODS[@]}"
for i in ${BMS[@]}; do
    runbm $i 1 $HOST $CLIENT
done

