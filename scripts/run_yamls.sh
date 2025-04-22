#!/bin/bash

set -ueo pipefail

#YAML_LOC=yamls/profile
YAML_LOC=yamls/profile/run3a

for f in $YAML_LOC/* #grad1.yaml
do
	echo "--------------"
	echo "FILENAME: $f"
	job_name=$(grep name $f | head -1 | awk -F: '{print $2}')
	echo "JOB NAME: $job_name"
	
	#continue
	oc apply -f $f
	
	#wait for job to complete
	while true
	do
		status=$(oc get job $job_name -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' || true)
		if [ "$status" == "True" ]
		then
			echo "Job $job_name completed"
			break
		fi
	done

	oc delete jobs $job_name
done
