#!/bin/bash

set -ueo pipefail

##YAML_LOC=yamls_host/may19protoscanhostnetwork/
YAML_LOC=yamls_host/may21protoscanhostnetworkncclfix/
LOG_LOC=$(echo $YAML_LOC | sed s:"yamls":"logs":g)

echo "YAML LOC: $YAML_LOC"
echo "LOG  LOC: $LOG_LOC"

if [ ! -d $LOG_LOC ]
then
	mkdir -p $LOG_LOC
fi	

for f in $YAML_LOC/*-grad1_*.yaml #grad1.yaml
do
	echo "--------------"
	echo "FILENAME: $f"
	job_name=$(grep name $f | head -1 | awk -F: '{print $2}')
	echo "JOB NAME: $job_name"
	TAG=$(echo $f | awk -F/ '{print $NF}' | sed s:".yaml":"":g)
	echo "TAG: $TAG"

	#LOG_FILE=stdout_$(echo $f | awk -F/ '{print $NF}' | sed s:".yaml":".log":g)	
	#echo "LOG LOC : $LOG_LOC/$LOG_FILE"
	#continue
	oc apply -f $f

	#wait for pods to spin up
	while [ $(oc get pods | grep torchrun-multipod | grep "Running" | wc -l) -eq 0 ] 
	do
		sleep 1
	done
	echo "Pods spun up"
	#oc wait --for=condition=Ready pod/${job_name}-0 --timeout=120s	

	#wait for job to complete
	while true
	do
		if oc logs ${job_name}-0 2>/dev/null | grep -q "Dumping final"
		then
                        echo "StatefulSet $job_name completed"
                        break
		fi
		sleep 1
	done
	
	echo "Dumping logs"
	#oc logs ${job_name}-0 > $LOG_LOC/$LOG_FILE
	oc cp torchrun-multipod-0:/tmp/logs $LOG_LOC/$TAG
	oc delete statefulset $job_name
	sleep 10
done
