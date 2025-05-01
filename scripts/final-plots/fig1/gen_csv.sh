#!/bin/bash

set -ueo pipefail

LOC=$1 #location of log files

OUTLOC=csvs
OUTFILE=`echo $LOC | awk -F"/" '{print $NF}'`".txt"
echo $OUTLOC/$OUTFILE

grep step -a $LOC/stdout* | grep "/10" | grep -v "1/10" | grep -v "2/10" | awk '{print $1, $14}' | sed s:"("::g > $OUTLOC/$OUTFILE
#if [ `wc -l $OUT_LOC/OUTFILE` != 80 ]
#then
#	echo "NOT EQUAL"
#fi

CSV_OUTFILE=`echo $OUTFILE | sed s:".txt":".csv":g`
echo $OUTLOC/$CSV_OUTFILE
awk -f process_grep.awk $OUTLOC/$OUTFILE > $OUTLOC/$CSV_OUTFILE
