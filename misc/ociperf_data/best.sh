#!/bin/bash
typeset -r SEP=','
typeset -r FIELD=${BW_FIELD:-14}
FLG=""

[[ $1 =~ ^\- ]] && {
   FLG=$1
   shift
}	
   
typeset -r -i num=$1
shift

[[ -z $num || $num = 0 ]] && {
   echo "USAGE: $0 [-r] <num> <csv files>" > /dev/stderr
   echo "  assumes bw is field 14 and prints num best bandwidths" > /dev/stderr
   echo "-r will reverse the sort and give you the worst values" 
   exit -1
}

cat $@ | grep '.*/sec$' | sort -n $FLG -t${SEP} -k ${FIELD} | tail -${num}
