#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <POD_NAME> <NODE_NAME> <POD_YAML>"
    exit 1
fi

echo "Creating pod: $1 on node: $2"

# Use envsubst to replace variables and apply the manifest
POD_NAME=$1 CONTAINER_NAME=$1 NODE_NAME=$2 envsubst < $3 | oc create -f -
sleep 2

echo "Deployment complete."

