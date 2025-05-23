#!/bin/bash

if [ ! -f bm_perftest_cpu.csv ]
then
	ln -s ../../../baremetal/perftest/perftest_cpu.csv bm_perftest_cpu.csv
fi

if [ ! -f bm_perftest_gpu.csv ]
then
	ln -s ../../../baremetal/perftest/perftest_gpu.csv bm_perftest_gpu.csv
fi

if [ ! -f oc_perftest_cpu.csv ]
then
	ln -s ../../../openshift/perftest/perftest_cpu.csv oc_perftest_cpu.csv
fi

if [ ! -f oc_perftest_gpu.csv ]
then
	ln -s ../../../openshift/perftest/perftest_gpu.csv oc_perftest_gpu.csv
fi
