#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

OPERATION=$1

if [[ "$OPERATION" == "enable" ]]; then
  nvidia-smi -pm 1
  gpufreq=$(nvidia-smi -i 0 --query-supported-clocks=gr --format=csv | cut -f 1 -d ' ' | sort -n -r | head -n 1)
  memfreq=$(nvidia-smi -i 0 --query-supported-clocks=mem --format=csv | cut -f 1 -d ' ' | sort -n -r | head -n 1)
  echo "GPU Max MEM $memfreq GPU $gpufreq"
  for idx in $(nvidia-smi -L |cut -f 1 -d :|cut -f 2 -d ' '|tr '\n' ' '); do
    nvidia-smi -i $idx -rac
    nvidia-smi -i $idx -ac $memfreq,$gpufreq
    nvidia-smi -i $idx -lgc $gpufreq,$gpufreq
    nvidia-smi -i $idx -lmc $memfreq,$memfreq
    nvidia-smi -i $idx -cc 1	
  done
  modprobe nvidia_peermem
elif [[ "$OPERATION" == "disable" ]]; then
  for idx in $(nvidia-smi -L |cut -f 1 -d :|cut -f 2 -d ' '|tr '\n' ' '); do
    nvidia-smi -i $idx -rac
    nvidia-smi -i $idx -rgc
    nvidia-smi -i $idx -rmc
    nvidia-smi -i $idx -cc 0
  done
else
  echo "Unknown option ${OPERATION}"
  exit 1
fi

