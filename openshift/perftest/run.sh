#!/bin/bash
# 
# Based primarily on test script in ../baremetal/perftest

typeset -r ts=$(date +%d-%m-%y-%s)

NIC="eno6np0"
HCA="mlx5_2"
FLAGS="-a -R -T 41 -F -x 3 -m 4096 --report_gbits -d ${HCA} -p 10000"
MTU=9000
BM_HOSTS="sriovlegacy-workload-uno sriovlegacy-workload-dos"
NUM_GPU=3
DRYRUN=0

function log()
{
    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG
}

typeset -a  hosts=()

hexec="oc exec"

hosts=(${BM_HOSTS})

LOGDIR="logs/run_cpu_${ts}"
IPRF_LOG="${LOGDIR}/bmperf.log"
mkdir -p $LOGDIR
log "hosts to be tested for cpu rdma:  ${hosts[@]}"
for srv in ${hosts[@]}; do
	srvip=`oc get pod ${srv} -o yaml | grep -E 'default/sriov-network' -A3 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`
	srvnode=`oc get pod ${srv} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
	for clt in ${hosts[@]}; do
        [[ $srv == $clt ]] && continue
		cltnode=`oc get pod ${clt} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
		for TEST in 'ib_write_bw' 'ib_read_bw'; do
			for QP in 1 2 4 8 16 32; do
				log "$TEST : Node ${srvnode} (Pod ${srv} - Interface IP ${srvip})  <->  Node ${cltnode} (Pod ${clt})"
				LOGFILE="${LOGDIR}/perftest_cpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
				COMMAND="$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} 2>&1 > ${LOGFILE} &" 
				log "${COMMAND}"
				if [ "$DRYRUN" -eq 0 ]; then
					eval "${COMMAND}" 
					sleep 1
				fi
				LOGFILE="${LOGDIR}/perftest_cpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
				COMMAND="$hexec ${clt} -- ${TEST} ${FLAGS} -q ${QP} ${srvip} 2>&1 > ${LOGFILE}"
				log "${COMMAND}"
				if [ "$DRYRUN" -eq 0 ]; then
					eval "${COMMAND}" 
					sleep 1
				fi
			done
		done
	done
done

LOGDIR="logs/run_gpu_${ts}"
IPRF_LOG="${LOGDIR}/bmperf.log"
mkdir -p $LOGDIR
log "hosts to be tested for gpu rdma:  ${hosts[@]}"
for srv in ${hosts[@]}; do 
	srvip=`oc get pod ${srv} -o yaml | grep -E 'default/sriov-network' -A3 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`
	srvnode=`oc get pod ${srv} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
	for clt in ${hosts[@]}; do
        [[ $srv == $clt ]] && continue
		cltnode=`oc get pod ${clt} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
		for ((GPU_S = 0; GPU_S <= $NUM_GPU; GPU_S++)); do #in {0..$NUM_GPU}; do
			for ((GPU_C = 0; GPU_C <= $NUM_GPU; GPU_C++)); do #in {0..$NUM_GPU}; do
			#for GPU_C in {0..$NUM_GPU}; do
				for TEST in 'ib_write_bw' 'ib_read_bw'; do
					for QP in 1 2 4 8 16 32; do
						log "$TEST : Node ${srvnode} (Pod ${srv} - Interface IP ${srvip}) [${GPU_S}] <-> [${GPU_C}] Node ${cltnode} (Pod ${clt})"
						LOGFILE="${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
						COMMAND="$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} --use_cuda=$GPU_S --use_cuda_dmabuf 2>&1 > ${LOGFILE} &"
						log "${COMMAND}"
						if [ "$DRYRUN" -eq 0 ]; then
							eval "${COMMAND}" 
							sleep 1
						fi
						LOGFILE="${LOGDIR}/perftest_gpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
						COMMAND="$hexec ${clt} -- ${TEST} ${FLAGS} -q ${QP} --use_cuda=$GPU_C --use_cuda_dmabuf ${srvip} 2>&1 > ${LOGFILE}"
						log "${COMMAND}"
						if [ "$DRYRUN" -eq 0 ]; then
							eval "${COMMAND}" 
							sleep 1
						fi
					done
				done
			done
		done
	done
done

