#!/bin/bash

set -ueox pipefail

CREATE_SOFTLINKS=${1:-0}
OUT_LOC=csvs
if [ $CREATE_SOFTLINKS -eq 1 ]
then
	ln -s ../../baremetal/gpt2/validation_noprofile/ logs_bm_noprofile
	ln -s ../../baremetal/gpt2/validation/ logs_bm_profile
	ln -s ../host-networking/logs_host/ logs_oc
fi

if [ ! -d $OUT_LOC ]
then
	mkdir -p $OUT_LOC
fi

./gen_csv.sh 'logs_oc/may19protoscanhostnetwork/multipod*profile0*' TEMP_oc $OUT_LOC/oc_may19_profile0.csv 1 
./gen_csv.sh 'logs_oc/may19protoscanhostnetwork/multipod*profile1*' TEMP_oc $OUT_LOC/oc_may19_profile1.csv 1
./gen_csv.sh 'logs_oc/may21protoscanhostnetworkncclfix/multipod*profile0*' TEMP_oc $OUT_LOC/oc_may21_profile0.csv 1
./gen_csv.sh 'logs_oc/may21protoscanhostnetworkncclfix/multipod*profile1*' TEMP_oc $OUT_LOC/oc_may21_profile1.csv 1
./gen_csv.sh 'logs_bm_noprofile/*' TEMP_bm $OUT_LOC/bm_noprofile.csv 0
./gen_csv.sh 'logs_bm_profile/*' TEMP_bm $OUT_LOC/bm_profile.csv 0 log

rm TEMP_*

set +x
ls csvs/ | paste | while read line; do echo -n $line","; done; echo

