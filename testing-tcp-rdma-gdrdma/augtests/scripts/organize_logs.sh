#!/bin/bash

set -ueo pipefail

LOC=$1

echo "Organizing logs for $LOC"

if [ ! -d $LOC/nccl ]
then
	mkdir $LOC/nccl
fi

if [ ! -d $LOC/nstat ]
then    
        mkdir $LOC/nstat
fi 

if [ ! -d $LOC/stdout ]
then    
        mkdir $LOC/stdout
fi 

if [ ! -d $LOC/topo ]
then
	mkdir $LOC/topo
fi

mv $LOC/nccl_* $LOC/nccl
mv $LOC/nstat_* $LOC/nstat
mv $LOC/stdout_* $LOC/stdout
mv $LOC/topo_* $LOC/topo
