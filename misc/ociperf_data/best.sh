#!/bin/bash
typeset -r SEP=','
typeset -r FIELD=${BW_FIELD:-14}
typeset -r -i num=$1
shift

[[ -z $num || $num = 0 ]] && {
   echo "USAGE: $0 <num> <csv files>" > /dev/stderr
   echo "  assumes bw is field 14 and prints num best bandwidths" > /dev/stderr
   exit -1
}	
 
sort -n -t${SEP} -k ${FIELD} $@  | tail -${num}
