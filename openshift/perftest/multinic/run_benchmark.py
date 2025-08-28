import argparse
import sys
import json
import os

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "num_gpus",
        type=int,
        default=4,
        help="The number of GPUs per node."
    )

    parser.add_argument(
        '--qpairs',
        type=int,
        default=6,
        help="Specify log base 2 of queue pair series. Example: 6 for [1,2,4,8,16,32]",
        metavar='<queue pair series>' # A hint for the help message
    )

    parser.add_argument(
        '--ports',
        type=lambda s: [item.strip() for item in s.split(',')],
        help="A comma-separated list of ports.",
        metavar='<port1,port2,...>'
    )

    parser.add_argument(
        '--os_ifs',
        type=lambda s: [item.strip() for item in s.split(',')],
        help="A comma-separated list of OS NIC interface names.",
        metavar='<if1,if2,...>'
    )

    parser.add_argument(
        '--mlx_ifs',
        type=lambda s: [item.strip() for item in s.split(',')],
        help="A comma-separated list of Mellanox interface names.",
        metavar='<mlx_1,mlx_2,...>'
    )

    parser.add_argument(
        '--pods',
        type=lambda s: [item.strip() for item in s.split(',')],
        help="A comma-separated list of pods.",
        metavar='<pod1,pod2,...>'
    )

    parser.add_argument(
        '--benchmarks',
        type=lambda s: [item.strip() for item in s.split(',')],
        default=["ib_read_bw","ib_write_bw","ib_read_lat","ib_write_lat"],
        help="A comma-separated list of benchmarks.",
        metavar='<bm1,bm2,...>'
    )

    parser.add_argument(
        '--flags',
        type=str,
        help="Specify flags",
		default="-a -R -T 41 -F -x 3 -m 4096 --report_gbits ",
        metavar='<flags>' # A hint for the help message
    )

    try:
        args = parser.parse_args()
    except argparse.ArgumentError as e:
        print(f"Error: {e}")
        parser.print_help()
        sys.exit(1)        

    if not (len(args.ports) & len(args.mlx_ifs) & len(args.os_ifs)):
        print("Error: number of ports and interfaces must be equal")
        sys.exit(1)

    return args
#define log():
#    echo $EPOCHSECONDS perf : $@ | tee -a  $IPRF_LOG

def getips(host,client):
    return 0
#    for ((p=0; p<${#NICS[@]}; p++)):
#        HOST_IPS[$p]=`oc exec ${h} -- ifconfig | grep -A 1 ${INTERFACES[$p]} | grep -oE "inet \b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed -e "s/inet //"`

def execcmds():
    return 0
#    exlogbase=$2

#    for ((i=0; i<${#NICS[@]}; i++)); do
#	d=${NICS[$i]}
#	p=${PORTS[$i]}
#	logfile="${exlogbase}_${d}_${p}_host.log"
#        host_cmd="${1} -d $d -p $p & 2&> ${logfile}"
#        echo "Host is $host_cmd"
#    done # Get all the hosts running first
#    for ((i=0; i<${#NICS[@]}; i++)); do
#	d=${NICS[$i]}
#	p=${PORTS[$i]}
#	h=${HOST_IPS[$i]}
#	logfile="${exlogbase}_${d}_${p}_${h}_client.log"
#        client_cmd="${1} -d $d -p $p $h & 2&> ${logfile}"
#        echo "Client is $client_cmd"
#    done

def runbm(bm,use_gpu,args):
    include_qps=0
    host=args.pods[0]
    client=args.pods[1]
    getips(host,client)

    if  bm == "ib_read_bw"  or bm == "ib_write_bw":
        include_qps=1 

    command=bm + args.flags

#    log_base="${LOGDIR}/"
#    LOGFILE="${LOGDIR}/perftest_gpu_srv_${TEST}_${MTU}_${QP}_${srvnode}_${cltnode}_${GPU_S}_${GPU_C}.log"

    if include_qps == 1:
        for qp in ([2**i for i in range(args.qpairs)]):
            command+="-q "+str(qp)
            if(use_gpu == 1):
                for g in range(args.num_gpus):
                    m=1        
	    	    #logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${QP}"
           #         ex_cmd_base="${cmd_base} -q ${qpair} --use_cuda=${g} --use_cuda_dmabuf"
	      	    #execcmds $ex_cmd_base $logfile base 
            else:
                m=2
	      #logfilebase="${log_base}perftest_${BM_OP}_${MTU}_${QP}"
	      #execcmds $ex_cmd_base $logfilebase
    else:
        if(use_gpu == 1):
            for g in range(args.num_gpus):
                m=1
		    #logfilebase="${log_base}perftest_gpu_${BM_OP}_${MTU}_${QP}"
       #             ex_cmd_base="${cmd_base} --use_cuda=${g} --use_cuda_dmabuf"
	      	#    execcmds $ex_cmd_base $logfilebase 
        else:
            m=2
	      #logfilebase="${log_base}perftest_${BM_OP}_${MTU}_${QP}"
	      #execcmds $cmd_base $logfilebase 

def main():
    args = parse_args()
    #IPRF_LOG="${LOGDIR}/cpu/bmperf.log"
    #log "Pods to be tested for cpu rdma:  ${PODS[@]}"
    for bm in args.benchmarks: 
        runbm(bm,0,args)
    #IPRF_LOG="${LOGDIR}/gpu/bmperf.log"
    #log "Pods to be tested for gpu rdma:  ${PODS[@]}"
    for bm in args.benchmarks:
        runbm(bm,1,args)


if __name__ == "__main__":
    main()
