#!/bin/bash

set -uo pipefail

# map mellanox card <-> interface name <-> gid (w/ RoCE v2 and gid with ffff:"IP of interface")

mlx_list=$(ls /sys/class/infiniband)

declare -A mlx_to_status
declare -A mlx_to_ifname
declare -A mlx_to_gid
declare -A mlx_to_gidstr
declare -A mlx_to_ip
declare -A mlx_to_desc


for mlx in ${mlx_list[@]} #loop over mellanox cards
do
	mlx_to_desc[$mlx]=$(lspci -s $(readlink /sys/class/infiniband/$mlx/device | awk -F/ '{print $NF}'))
	for gid in $(ls -v /sys/class/infiniband/$mlx/ports/1/gid_attrs/ndevs) #loop over all gids
	do
		if [ -f /sys/class/infiniband/$mlx/ports/1/gid_attrs/ndevs/$gid ]
		then
			type=$(cat /sys/class/infiniband/$mlx/ports/1/gid_attrs/types/$gid 2>/dev/null)
			if [[ $? -ne 0 ]] #only initial K (variable) gids are set. once hit invalid gid, skip to next mellanox nic
			then
				continue
			fi

			#valid conditions for appropriate gid. store values in associative arrays
			if [[ "$type" == "RoCE v2" && $(cat /sys/class/infiniband/$mlx/ports/1/gids/$gid) =~ ^"0000:0000:0000:0000:0000:ffff" ]] #good candidates
			then
				ifname=$(cat /sys/class/infiniband/$mlx/ports/1/gid_attrs/ndevs/$gid)
				gid_str=$(cat /sys/class/infiniband/$mlx/ports/1/gids/$gid)
				ip=$(ip -4 addr show $ifname | awk '/inet/ {print $2}')
				#echo $mlx, $gid, $gid_str, $type, $ifname, $ip

				mlx_to_ifname[$mlx]=$ifname
				mlx_to_gid[$mlx]=$gid
				mlx_to_gidstr[$mlx]=$gid_str
				mlx_to_ip[$mlx]=$ip
				mlx_to_status[$mlx]=0
			else
				mlx_to_status[$mlx]=1
			fi
		fi
	done
done

for mlx in ${!mlx_to_status[@]}
do
	echo $mlx
	echo -e "\t" ${mlx_to_status[$mlx]}
	echo -e "\t" ${mlx_to_desc[$mlx]}
	echo -e "\t" ${mlx_to_ifname[$mlx]:-"None"}
	echo -e "\t" ${mlx_to_ip[$mlx]:-"None"}
	echo -e "\t" ${mlx_to_gidstr[$mlx]:-"None"}
	echo -e "\t" ${mlx_to_gid[$mlx]:-"None"}
done	

