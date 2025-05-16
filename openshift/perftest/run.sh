#!/bin/bash
# 
# Based primarily on test script in ../baremetal/perftest

typeset -r ts=$(date +%d-%m-%y-%s)

NIC="eno6np0"
HCA="mlx5_2"
FLAGS=" -a -F -R -T 41  --report_gbits  -d ${HCA} "
MTU=9000
BM_HOSTS="sriovlegacy-workload-uno sriovlegacy-workload-dos"

function log()
{
    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG
}

typeset -a  hosts=()

dryrun=1

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
				log "$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} 2&>1 > ${LOGFILE}"
				if [ "$dryrun" -eq 0 ]; then
					$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} 2&>1 > ${LOGFILE} &
					sleep 1
				fi
				LOGFILE="${LOGDIR}/perftest_cpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
				log "$hexec ${clt} --  ${TEST} ${FLAGS} -q ${QP} ${srvip} 2&>1 > ${LOGFILE}"
				if [ "$dryrun" -eq 0 ]; then
					$hexec ${clt} -- ${TEST} ${FLAGS} -q ${QP} ${srvip} 2&>1 > ${LOGFILE}
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
		for GPU_S in {0..3}; do
			for GPU_C in {0..3}; do
				for TEST in 'ib_write_bw' 'ib_read_bw'; do
					for QP in 1 2 4 8 16 32; do
						log "$TEST : Node ${srvnode} (Pod ${srv} - Interface IP ${srvip}) [${GPU_S}] <-> [${GPU_C}] Node ${cltnode} (Pod ${clt})"
						LOGFILE="${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
						log "$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} --use_cuda=$GPU_S --use_cuda_dmabuf 2&>1 > ${LOGFILE}"
						if [ "$dryrun" -eq 0 ]; then
							$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} 2&>1 > ${LOGFILE} &
							sleep 1
						fi
						LOGFILE="${LOGDIR}/perftest_gpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"
						log "$hexec ${srv} -- ${TEST} ${FLAGS} -q ${QP} --use_cuda=$GPU_C --use_cuda_dmabuf ${srvip} 2&>1 > ${LOGFILE}"
						if [ "$dryrun" -eq 0 ]; then
							$hexec ${clt} -- ${TEST} ${FLAGS} -q ${QP} --use_cuda=$GPU_C --use_cuda_dmabuf ${srvip} 2&>1 > ${LOGFILE} 
							sleep 1
						fi
					done
				done
			done
		done
	done
done

