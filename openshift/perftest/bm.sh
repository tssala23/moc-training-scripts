#!/bin/bash
# 
# Based primarily on test script in ../baremetal/perftest

typeset -r ts=$(date +%d-%m-%y-%s)

NICS=("cx7_eno5","cx7_eno6","cx7_eno7","cx7_eno8") #FIXME: Check within node
HCAS=("mlx5_2") #FIXME: This needs to be an array matching within node
FLAGS="-a -R -T 41 -F -x 3 -m 4096 -p 10000 --report_gbits -d ${HCA} "
MTU=9000
BM_HOSTS="sr4n1 sr4n2 sr4n3 sr4n4"
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
	srvipbase=`oc get pod ${srv} -o yaml | grep -E 'default/network-cx7-eno5np' -A3 | grep -oE "\b([0-9]{1,3}\.){3}\b"`
	srvips = ("${srvipbase}.5" "${srvipbase}.6" "${srvipbase}.7" "${srvipbase}.8")
	srvnode=`oc get pod ${srv} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
	for clt in ${hosts[@]}; do
        [[ $srv == $clt ]] && continue
		cltnode=`oc get pod ${clt} -o wide | tail -n1 | tr -s ' ' | cut -d' ' -f7`
		for TEST in 'ib_write_bw' 'ib_read_bw'; do
			for QP in 1 2; do
			#for QP in 1 2 4 8 16 32; do
			#for cltdev in; do
			#for srvip in; do
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

