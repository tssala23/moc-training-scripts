#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: ${1} <enable|disable>"
fi

OPERATION=$1

if [[ "$OPERATION" == "enable" ]]; then
  for i in $(ls -v /sys/class/net/); do
    if [ -d /sys/class/net/$i/device ]; then
      for e in $(ls -v /sys/class/net/$i/device/net/); do
        echo "$i: $e"
        ethtool -G $e tx 8192
        ethtool -G $e rx 8192 
        ip link set $e txqueuelen 10000 
        ip link set dev $e mtu 9000 
      done
    fi
  done

  sysctl -w net.ipv4.tcp_timestamps=0  
  sysctl -w net.ipv4.tcp_sack=1    
  sysctl -w net.core.netdev_max_backlog=250000  
  sysctl -w net.core.rmem_max=4194304 

  sysctl -w net.core.wmem_max=4194304 
  sysctl -w net.core.rmem_default=4194304 
  sysctl -w net.core.wmem_default=4194304 
  sysctl -w net.core.optmem_max=4194304 
  sysctl -w net.ipv4.tcp_rmem="4096 87380 4194304" 
  sysctl -w net.ipv4.tcp_wmem="4096 65536 4194304" 
  sysctl -w net.ipv4.tcp_low_latency=1

  sysctl -w net.ipv4.conf.all.arp_announce=2 
  sysctl -w net.ipv4.conf.all.arp_filter=1   
  sysctl -w net.ipv4.conf.all.arp_ignore=2  
  ip -s neigh flush all

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
  for i in $(ls -v /sys/class/net/); do
    if [ -d /sys/class/net/$i/device ]; then
      for e in $(ls -v /sys/class/net/$i/device/net/); do
        echo "$i: $e"
        ethtool -G $e tx 1024
        ethtool -G $e rx 1024
        ip link set $e txqueuelen 1000 
        ip link set dev $e mtu 9000 
      done
    fi
  done

  sysctl -w net.ipv4.tcp_timestamps=1
  sysctl -w net.ipv4.tcp_sack=1
  sysctl -w net.core.netdev_max_backlog=1000
  sysctl -w net.core.rmem_max=212992

  sysctl -w net.core.wmem_max=212992
  sysctl -w net.core.rmem_default=212992
  sysctl -w net.core.wmem_default=212992
  sysctl -w net.core.optmem_max=81920
  sysctl -w net.ipv4.tcp_rmem="4096 131072 6291456"
  sysctl -w net.ipv4.tcp_wmem="4096 16384 4194304"
  sysctl -w net.ipv4.tcp_low_latency=0

  sysctl -w net.ipv4.conf.all.arp_announce=2
  sysctl -w net.ipv4.conf.all.arp_filter=0 
  sysctl -w net.ipv4.conf.all.arp_ignore=0
  ip -s neigh flush all


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

