#!/bin/bash

set -euo pipefail

folder=$1
prefile=$(ls $folder/nstat_pre*)
postfile=$(ls $folder/nstat_post*)

declare -A counts
for field in TcpInSegs TcpOutSegs
do
	declare -A counts
	for file in $prefile $postfile
	do
		n=$(grep $field $file | awk '{print $2}')
		counts[$(echo $file | awk -F/ '{print $NF}' | awk -F_ '{print $2}')]=${n:-0}
	done
	echo $field, ${counts["pre"]}, ${counts["post"]}, $((${counts["post"]}-${counts["pre"]}))
done
