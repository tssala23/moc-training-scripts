#!/bin/bash

command=$1
mode=$2
last_byte=$3

if [ "$command" != "ib_read_lat" ]; then
  qp="-q 8"
fi

devs=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
gpus=("0" "1" "2" "3")
ips=("192.168.101.${last_byte}" "192.168.100.${last_byte}" "192.168.103.${last_byte}" "192.168.102.${last_byte}")


for (( d=0; d<4; d++ ))
do
  dev=${devs[$d]}
  ip=${ips[$d]}

  for (( g=0; g<4; g++ ))
  do
    gpu=${gpus[$g]}
    if [ "$mode" == "host" ]; then
      ${command} -a -R -T 41 -F -x 3 -m 4096 ${qp} --report_gbits -d ${dev} --use_cuda=${gpu} --use_cuda_dmabuf | tee ${command}_${mode}_${dev}_${gpu}.log
    elif [ "$mode" == "client" ]; then
      ${command} -a -R -T 41 -F -x 3 -m 4096 ${qp} --report_gbits -d ${dev} --use_cuda=${gpu} --use_cuda_dmabuf $ip | tee ${command}_${mode}_${dev}_${gpu}.log
      sleep 1
    else
      exit 1
    fi
  done
done


