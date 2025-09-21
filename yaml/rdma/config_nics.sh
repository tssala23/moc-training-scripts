#!/bin/bash

echo "This requires a reboot afterwards before taking effect" 

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

OPERATION=$1


if [[ "$OPERATION" == "enable" ]]; then
  mlxconfig -y -d 0000:03:00.0 ADVANCED_PCI_SETTINGS=1
  mlxconfig -y -d 0000:03:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:c3:00.0 ADVANCED_PCI_SETTINGS=1
  mlxconfig -y -d 0000:c3:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:a3:00.0 ADVANCED_PCI_SETTINGS=1
  mlxconfig -y -d 0000:a3:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:23:00.0 ADVANCED_PCI_SETTINGS=1
  mlxconfig -y -d 0000:23:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1
elif [[ "$OPERATION" == "disable" ]]; then
  mlxconfig -y -d 0000:03:00.0 ADVANCED_PCI_SETTINGS=0
  mlxconfig -y -d 0000:03:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:c3:00.0 ADVANCED_PCI_SETTINGS=0
  mlxconfig -y -d 0000:c3:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:a3:00.0 ADVANCED_PCI_SETTINGS=0
  mlxconfig -y -d 0000:a3:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1

  mlxconfig -y -d 0000:23:00.0 ADVANCED_PCI_SETTINGS=0
  mlxconfig -y -d 0000:23:00.0 MAX_ACC_OUT_READ=128 RDMA_SELECTIVE_REPEAT_EN=1 ATS_ENABLED=1
else
  echo "Unknown option ${OPERATION}"
  exit 1
fi
