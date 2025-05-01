#!/bin/bash

set -ueo pipefail


cp ../../../baremetal/gpt2/tcp/logs/*multisocket* ./bm_nodes2

cp -r ../../../logs/logs_profile0_npods1_nprocs4_oc417 oc_npods1
cp -r ../../../logs/logs_profile0_npods2_nprocs4_oc417 oc_npods2
cp -r ../../../logs/logs_profile0_npods4_nprocs4_oc417 oc_npods4
cp -r ../../../logs/logs_profile0_npods8_nprocs4_oc417 oc_npods8

./gen_csv.sh oc_npods1
./gen_csv.sh oc_npods2
./gen_csv.sh oc_npods4
./gen_csv.sh oc_npods8


