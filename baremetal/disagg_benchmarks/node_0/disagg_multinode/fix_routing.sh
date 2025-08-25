#!/bin/bash
declare -a TABLE=(
    "default via 192.168.50.254 dev eno2np0 proto dhcp src 192.168.50.182 metric 100"
    "169.254.169.254 via 192.168.50.11 dev eno2np0 proto dhcp src 192.168.50.182 metric 100"
    "192.168.50.0/24 dev eno2np0 proto kernel scope link src 192.168.50.182 metric 100"
    "192.168.60.173 dev eno7np0 scope link src 192.168.60.111"
    "192.168.60.184 dev eno5np0 scope link src 192.168.60.186"
    "192.168.60.193 dev eno6np0 scope link src 192.168.60.185"
    "192.168.60.198 dev eno8np0 scope link src 192.168.60.103"
)

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (or with sudo)"
   exit 1
fi

echo "--- Phase 1: Removing routes not in the desired table ---"

declare -A desired_routes
for route in "${TABLE[@]}"; do
    sanitized_route=$(echo "$route" | xargs)
    desired_routes["$sanitized_route"]=1
done

while IFS= read -r current_route; do
    sanitized_current_route=$(echo "$current_route" | xargs)
    
    if [[ -z "${desired_routes[$sanitized_current_route]}" ]]; then
        echo "Deleting: $sanitized_current_route"
        ip route del $sanitized_current_route
    else
        echo "Keeping:  $sanitized_current_route"
    fi
done < <(ip route show)


echo -e "\n--- Phase 2: Adding missing routes from the desired table ---"

declare -A current_routes_map
while IFS= read -r route; do
    sanitized_route=$(echo "$route" | xargs)
    [[ -n "$sanitized_route" ]] && current_routes_map["$sanitized_route"]=1
done < <(ip route show)

for desired_route in "${TABLE[@]}"; do
    sanitized_desired_route=$(echo "$desired_route" | xargs)
    
    if [[ -z "${current_routes_map[$sanitized_desired_route]}" ]]; then
        echo "Adding:   $sanitized_desired_route"
        ip route add $sanitized_desired_route
    else
        echo "Exists:   $sanitized_desired_route"
    fi
done

echo -e "\nSynchronization complete."

echo -e "\nApplying ARP and neighbor settings..."
sysctl -w net.ipv4.conf.eno5np0.arp_filter=1
sysctl -w net.ipv4.conf.eno6np0.arp_filter=1
sysctl -w net.ipv4.conf.eno7np0.arp_filter=1
sysctl -w net.ipv4.conf.eno8np0.arp_filter=1
sysctl -w net.ipv4.conf.all.arp_announce=2
sysctl -w net.ipv4.conf.all.arp_ignore=1
ip neigh flush dev eno5np0
ip neigh flush dev eno6np0
ip neigh flush dev eno7np0
ip neigh flush dev eno8np0

