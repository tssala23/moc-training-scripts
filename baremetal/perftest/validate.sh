#!/bin/bash
typeset -r ts=$(date +%d-%m-%y-%s)

NIC="eno6np0"
HCA="mlx5_2"
FLAGS=" -a -R -T 41 -F  -x 3 -m 4096 -p 10000 --report_gbits  -d ${HCA} "
MTU=9000
QP=1
NSYS_CMD="nsys profile --trace=cuda,nvtx,osrt --output /tmp/report.nsys-rep --force-overwrite true"
GPU=0
TEST="ib_write_bw"

function log()
{
    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG
}

typeset -a  hosts=()

hcp="scp -o ProxyJump=${BM_USER}@${BM_FLOATING_IP}"
hexec_srv="ssh -f -J ${BM_USER}@${BM_FLOATING_IP}"
hexec_clt="ssh -J ${BM_USER}@${BM_FLOATING_IP}"


srv="192.168.50.173"
clt="192.168.50.166"
srvip=$($hexec_clt ${BM_USER}@${srv} "ip -4 addr show dev ${NIC} | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
srvnode=$($hexec_clt ${BM_USER}@${srv} 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')
cltnode=$($hexec_clt ${BM_USER}@${clt} 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')


LOGDIR="validate/run_cpu_${ts}"
IPRF_LOG="${LOGDIR}/bmperf.log"
mkdir -p $LOGDIR

log "$TEST : Node ${srvnode} (${srv} - ${srvip})  <->  Node ${cltnode} (${clt})"
log "$hexec_srv ${BM_USER}@${srv} \"nstat --reset > /dev/null; nstat > /tmp/nstat_cpu_pre; ${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP}  > /tmp/perftest_log ; nstat > /tmp/nstat_cpu_post\""
$hexec_srv ${BM_USER}@${srv} "nstat --reset > /dev/null; nstat > /tmp/nstat_cpu_pre; ${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP}  > /tmp/perftest_log ; nstat > /tmp/nstat_cpu_post"
sleep 10
log "$hexec_clt ${BM_USER}@${clt} \"${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} ${srvip} > /tmp/perftest_log 2>&1\" 2>&1 | tee -a /tmp/perftest_log"
$hexec_clt ${BM_USER}@${clt} "${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} ${srvip} > /tmp/perftest_log 2>&1" 2>&1 | tee -a /tmp/perftest_log
sleep 1
$hcp ${BM_USER}@${srv}:/tmp/perftest_log "${LOGDIR}/perftest_cpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
$hcp ${BM_USER}@${clt}:/tmp/perftest_log "${LOGDIR}/perftest_cpu_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
$hcp ${BM_USER}@${srv}:/tmp/report.nsys-rep "${LOGDIR}/perftest_cpu_srv.nsys-rep"
$hcp ${BM_USER}@${clt}:/tmp/report.nsys-rep "${LOGDIR}/perftest_cpu_clt.nsys-rep"
$hcp ${BM_USER}@${srv}:/tmp/nstat_cpu_pre "${LOGDIR}/nstat_cpu_pre"
$hcp ${BM_USER}@${srv}:/tmp/nstat_cpu_post "${LOGDIR}/nstat_cpu_post"

LOGDIR="validate/run_gpu_${ts}"
IPRF_LOG="${LOGDIR}/bmperf.log"
mkdir -p $LOGDIR


log "$TEST : Node ${srvnode} (${srv} - ${srvip})  <->  Node ${cltnode} (${clt})"
log "$hexec_srv ${BM_USER}@${srv} \"nstat --reset > /dev/null; nstat > /tmp/nstat_gpu_pre; ${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} --use_cuda=${GPU} --use_cuda_dmabuf  > /tmp/perftest_log ; nstat > /tmp/nstat_gpu_post\""
$hexec_srv ${BM_USER}@${srv} "nstat --reset > /dev/null; nstat > /tmp/nstat_gpu_pre;  ${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} --use_cuda=${GPU} --use_cuda_dmabuf  > /tmp/perftest_log  ; nstat > /tmp/nstat_gpu_post "
sleep 10
log "$hexec_clt ${BM_USER}@${clt} \"${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} --use_cuda=${GPU} --use_cuda_dmabuf  ${srvip} > /tmp/perftest_log 2>&1\" 2>&1 | tee -a /tmp/perftest_log"
$hexec_clt ${BM_USER}@${clt} "${NSYS_CMD} ./perftest/$TEST $FLAGS -q ${QP} --use_cuda=${GPU} --use_cuda_dmabuf  ${srvip} > /tmp/perftest_log 2>&1" 2>&1 | tee -a /tmp/perftest_log
sleep 1
$hcp ${BM_USER}@${srv}:/tmp/perftest_log "${LOGDIR}/perftest_gpu${GPU}_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
$hcp ${BM_USER}@${clt}:/tmp/perftest_log "${LOGDIR}/perftest_gpu${GPU}_clt_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}.log"
$hcp ${BM_USER}@${srv}:/tmp/report.nsys-rep "${LOGDIR}/perftest_gpu${GPU}_srv.nsys-rep"
$hcp ${BM_USER}@${clt}:/tmp/report.nsys-rep "${LOGDIR}/perftest_gpu${GPU}_clt.nsys-rep"
$hcp ${BM_USER}@${srv}:/tmp/nstat_gpu_pre "${LOGDIR}/nstat_gpu_pre"
$hcp ${BM_USER}@${srv}:/tmp/nstat_gpu_post "${LOGDIR}/nstat_gpu_post"

				


