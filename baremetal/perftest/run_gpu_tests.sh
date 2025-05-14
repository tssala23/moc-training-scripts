#!/bin/bash
typeset -r ts=$(date +%d-%m-%y-%s)

QP=16
NIC="eno6np0"
HCA="mlx5_2"
FLAGS=" -a -F  --report_gbits -q ${QP} -d ${HCA} "
LOGDIR="logs/run_gpu_${ts}"
IPRF_LOG="${LOGDIR}/bmperf.log"
MTU=9000
#BM_HOSTS="192.168.50.92 192.168.50.96 192.168.50.81 192.168.50.172 192.168.50.134 192.168.50.105 192.168.50.173 192.168.50.166"
BM_HOSTS="192.168.50.173 192.168.50.166"

function log()
{
    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG
}

typeset -a  hosts=()

mkdir -p $LOGDIR

hcp="scp -o ProxyJump=${BM_USER}@${BM_FLOATING_IP}"
hexec="ssh -J ${BM_USER}@${BM_FLOATING_IP}"
hosts=(${BM_HOSTS})

log "hosts to be tested:  ${hosts[@]}"

for srv in ${hosts[@]}; do #0 1 2 3 4 5 6 7; do
	srvip=$($hexec ${BM_USER}@${srv} "ip -4 addr show dev ${NIC} | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
	srvnode=$($hexec ${BM_USER}@${srv} 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')
	for clt in ${hosts[@]}; do
        [[ $srv == $clt ]] && continue
		cltnode=$($hexec ${BM_USER}@${clt} 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')
		for GPU_S in {0..3}; do
			for GPU_C in {0..3}; do
				for TEST in 'ib_write_bw' 'ib_read_bw'; do
					echo "check"
					log "$TEST : Node ${srvnode} (${srv}/ - ${srvip}) [${GPU_S}] <-> [${GPU_C}] Node ${cltnode} (${clt})"
					log "$hexec ${BM_USER}@${srv} \"./perftest/$TEST $FLAGS --use_cuda=$GPU_S --use_cuda_dmabuf > /tmp/perftest_log 2>&1 &\" 2>&1 | tee -a /tmp/perftest_log"
					$hexec ${BM_USER}@${srv} "./perftest/$TEST $FLAGS --use_cuda=$GPU_S --use_cuda_dmabuf > /tmp/perftest_log 2>&1 &" 2>&1 | tee -a /tmp/perftest_log
					sleep 1
					log "$hexec ${BM_USER}@${clt} \"./perftest/$TEST $FLAGS --use_cuda=$GPU_C --use_cuda_dmabuf ${srvip} > /tmp/perftest_log 2>&1\" 2>&1 | tee -a /tmp/perftest_log"
					$hexec ${BM_USER}@${clt} "./perftest/$TEST $FLAGS --use_cuda=$GPU_C --use_cuda_dmabuf ${srvip} > /tmp/perftest_log 2>&1" 2>&1 | tee -a /tmp/perftest_log
					$hcp ${BM_USER}@${srv}:/tmp/perftest_log "${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
					$hcp ${BM_USER}@${clt}:/tmp/perftest_log "${LOGDIR}/perftest_gpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
				done
			done
		done
	done
done
