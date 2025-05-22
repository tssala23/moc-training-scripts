#!/bin/bash

set -ueo pipefail

LOC=$1
OUT_FILE=$2
CSV_FILE=$3
OC=$4
TAG=${5:-"stdout"}

if [ $OC -eq 0 ]
then
	script=process_grep_bm.awk
else
	script=process_grep.awk
fi

grep step -a $LOC/$TAG* | grep "/10" | grep -v "1/10" | grep -v "2/10" | awk '{print $1, $14}' | sed s:"("::g > $OUT_FILE

awk -f $script $OUT_FILE > $CSV_FILE
