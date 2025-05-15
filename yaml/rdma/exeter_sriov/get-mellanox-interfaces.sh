#!/bin/bash

# Get list of worker nodes
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name | cut -d'/' -f2)

# Check if nodes were found
if [ -z "$WORKER_NODES" ]; then
  echo "Error: No worker nodes found. Check your cluster or node labels."
  exit 1
fi

# Script to run on each node
SCRIPT=$(cat << 'EOF'
for d in $(lspci -Dn -d 15b3: | cut -d' ' -f1); do
  device_info=$(lspci -nn -s $d | grep -i mellanox)
  if [ -n "$device_info" ]; then
    if [ -d /sys/bus/pci/devices/$d/net ]; then
      for iface in /sys/bus/pci/devices/$d/net/*; do
        echo "$d -> $(basename $iface) -> $device_info"
      done
    else
      echo "$d -> No network interface -> $device_info"
    fi
  fi
done
EOF
)

# Iterate over each worker node
for NODE in $WORKER_NODES; do
  echo "=== Checking node: $NODE ==="
  oc debug "node/$NODE" -- /bin/bash -c "$SCRIPT" 2>&1 || {
    echo "Error: Failed to run debug command on node $NODE"
    continue
  }
  echo ""
done


