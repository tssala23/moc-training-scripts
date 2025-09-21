#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

OPERATION=$1

declare -A originals

originals["01:00.0"]="0026"
originals["02:00.0"]="0026"
originals["03:00.0"]="2936"
originals["04:00.0"]="0026"
originals["05:00.0"]="0026"
originals["21:00.0"]="0026"
originals["22:00.0"]="0026"
originals["22:02.0"]="0026"
originals["23:00.0"]="2936"
originals["24:00.0"]="0026"
originals["25:00.0"]="0026"
originals["42:00.0"]="2956"
originals["42:00.1"]="2956"
originals["a1:00.0"]="0026"
originals["a2:00.0"]="0026"
originals["a2:02.0"]="0026"
originals["a3:00.0"]="2936"
originals["a4:00.0"]="0026"
originals["a5:00.0"]="0026"
originals["c1:00.0"]="0026"
originals["c2:00.0"]="0026"
originals["c2:02.0"]="0026"
originals["c3:00.0"]="2936"
originals["c4:00.0"]="0026"
originals["c5:00.0"]="0026"

# NIC 4k MRR (+ 512 MPS) for ConnectX. CX7 default is 2934
d=$(lspci |grep Mellanox|head -n 1|awk '{print $1}')
if [ "$(lspci -vvv -s $d |grep MaxReadReq|awk '{print $5}')" == "4096" ]; then
  echo "Mellanox devices may have 4k MRR by default. Skip MRR setting."
else
  if [[ "$OPERATION" == "enable" ]]; then
    for d in $(lspci |grep Mellanox|awk '{print $1}'); do
      V=$(setpci -s $d 68.w)
      vDEC=$((16#$V))
      hMASK=8FFF # 4k MRR only # 8F1F if 4k MRR + 512 MPS
      dMASK=$((16#$hMASK))
      dMASKED=$(( vDEC & dMASK ))
      hNV=5000 # 4k MRR only # 5040 if 4k MRR + 512 MPS
      dNV=$((16#$hNV))
      dVAL=$(( dMASKED | dNV ))
      hVAL=$(printf '%x' $dVAL)
      setpci -s $d 68.w=$hVAL
    done
  elif [[ "$OPERATION" == "disable" ]]; then
    for d in $(lspci |grep Mellanox|awk '{print $1}'); do
      setpci -s $d 68.w=${originals[$d]}
    done
  else
    echo "Unknown option ${OPERATION}"
    exit 1
  fi
fi

