#!/bin/bash

set -ueo pipefail

wait_for_rocev2_gid() {
  local iface=$1
  local index=${2:-3}
  local max_attempts=10

  local ibdev=$(basename "$(readlink -f /sys/class/net/$iface/device/infiniband/mlx5_*)")
  local gid_path="/sys/class/infiniband/$ibdev/ports/1/gids/$index"
  local type_path="/sys/class/infiniband/$ibdev/ports/1/gid_attrs/types/$index"

  echo "[WAIT] $iface ($ibdev) → Waiting for GID[$index] to be valid..."

  for attempt in $(seq 1 $max_attempts); do
    if [[ -f $gid_path && -f $type_path ]]; then
      gid=$(cat $gid_path)
      type=$(cat $type_path)
      if [[ "$type" == "RoCE v2" && "$gid" =~ :ffff: ]]; then
        echo "[OK] $iface → $gid ($type)"
        return 0
      fi
    fi
    sleep 5
  done

  echo "[ERROR] $iface → GID[$index] not ready after $max_attempts seconds"
  return 1
}


#GOAL: for each interface associated with a mellanox card, assign ip addresses on different subnets and set gids appropriately so traffic can be routed correctly

#one subnet per nic
SUBNET_BASES=("192.168.90" "192.168.91" "192.168.92" "192.168.93")

#interface names
IFNAMES=("eno6np0" "eno5np0" "eno7np0" "eno8np0")
MLXNAMES=("mlx5_2" "mlx5_3" "mlx5_4" "mlx5_5")
#associated with mlx5_2 mlx5_3 mlx5_4 mlx5_5

POD_NAME=${POD_NAME:-$(hostname)}
POD_INDEX=${POD_NAME##*-}
NETMASK="/24"

#ip assigned to each NIC
#subnet:(pod_index+100)
for i in "${!IFNAMES[@]}" #loop over indices - "!"
do
	#construct ip
	IFNAME="${IFNAMES[$i]}"
	SUBNET="${SUBNET_BASES[$i]}"
	IP_LAST_OCTET=$((100 + POD_INDEX))
	IP_ADDR="${SUBNET}.${IP_LAST_OCTET}"
	
	echo "[assign_ips] ${IFNAME} has IP ${IP_ADDR}"
	
	#clean up old ips (assigned if another pod was scheduled on this node)
	for ip in $(ip -4 addr show dev "$IFNAME" | awk '/inet / {print $2}')
	do
		if [[ "$ip" == ${SUBNET}.* ]]
		then
			echo [assign_ips] Flushing old IP $ip from $IFNAME
			ip addr del "$ip" dev "$IFNAME"
		fi
	done

	#assign new ip to interface
	ip addr add "${IP_ADDR}${NETMASK}" dev "$IFNAME"
	ip link set "$IFNAME" up
	sleep 2
	wait_for_rocev2_gid $IFNAME 3

	#GID entries should get populated automatically under
	#/sys/class/infiniband/mlx5_*/ports/1/gids/[0-3]
	mlx="${MLXNAMES[$i]}"
	for g in /sys/class/infiniband/$mlx/ports/1/gids/[0-3];
	do
		echo "$mlx - $(cat $g)"
	done

        for g in /sys/class/infiniband/$mlx/ports/1/gid_attrs/types/[0-3];
        do
                echo "$mlx - $(cat $g)"
        done

done

