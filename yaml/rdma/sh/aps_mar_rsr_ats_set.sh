#!/bin/bash

echo "This requires a reboot afterwards before taking effect" 

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

OPERATION=$1

for d in $(mlxconfig query |grep Device:|awk '{print $2}'); do
  if [[ "$OPERATION" == "enable" ]]; then
    mlxconfig -y -d $d s ADVANCED_PCI_SETTINGS=1
    mlxconfig -y -d $d s MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1
  elif [[ "$OPERATION" == "disable" ]]; then
    mlxconfig -y -d $d s MAX_ACC_OUT_READ=0 RDMA_SELECTIVE_REPEAT_EN=0 ATS_ENABLED=0
    mlxconfig -y -d $d s ADVANCED_PCI_SETTINGS=0
  else
    echo "Unknown option ${OPERATION}"
    exit 1
  fi
done

