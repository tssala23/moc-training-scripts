#!/bin/bash

# NIC 4k MRR (+ 512 MPS) for ConnectX. CX7 default is 2934
d=$(lspci |grep Mellanox|head -n 1|awk '{print $1}')
if [ "$(lspci -vvv -s $d |grep MaxReadReq|awk '{print $5}')" == "4096" ]; then
  echo "Mellanox devices may have 4k MRR by default. Skip MRR setting."
else
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
fi

