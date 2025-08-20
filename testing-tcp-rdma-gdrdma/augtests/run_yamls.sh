#!/bin/bash

set -ueo pipefail

YAML_LOC=$1
LOG_LOC=$(echo $YAML_LOC | sed s:"yamls":"logs":g)
PRINT=${2:-1}

echo "YAML LOC: $YAML_LOC"
echo "LOG  LOC: $LOG_LOC"

if [ ! -d $LOG_LOC ]
then
	mkdir -p $LOG_LOC
fi	

#for f in $YAML_LOC/*.yaml
for f in $YAML_LOC/*pods2*nic4*
do
	echo "--------------"
	echo "YAML FILENAME: $f"

	if [[ $PRINT -eq 1 ]]
	then
		continue
	fi

	oc apply -f $f
	job_name=torchrun-multipod

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
	oc cp torchrun-multipod-0:/tmp/logs $LOG_LOC
	oc delete statefulset $job_name

	TAG=$(echo $f | awk -F/ '{print $NF}' | sed s:".yaml"::g)
	mv $LOG_LOC/topo.xml $LOG_LOC/topo_$TAG.xml
	sleep 10
done
