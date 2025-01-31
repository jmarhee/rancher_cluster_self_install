#!/bin/bash

# Variables
export CLUSTER_NAME="name of cluster (hostname -s on the first node or get from Rancher)"
# Set Variables either in env outside scripts as exports, or manually here:
# export RANCHER_API_URL="https://rancher.your.organization.tld" # Do not set /v1 or /v3 URI here
# export RANCHER_ACCESS_KEY="token-xxxx"
# export RANCHER_SECRET_KEY="xxxx"

#Build Config
ROLES="--worker"

# Retrieve Cluster ID from Rancher
clusters_response=$(curl --insecure -s -u "$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY" -X GET \
  -H "Content-Type: application/json" \
  "$RANCHER_API_URL/v3/clusters?name=$CLUSTER_NAME")

target_cluster_id=$(echo "$clusters_response" | jq -r '.data[] | select(.name=="'"$CLUSTER_NAME"'") | .id')

if [ -z "$target_cluster_id" ]; then
  echo "Cluster with name '$CLUSTER_NAME' not found."
  exit 1
else
  echo "Cluster ID for '$CLUSTER_NAME' is '$target_cluster_id'."
fi

# Request insecureNodeToken and append roles.
registration_command_response=$(curl --insecure -s -u "$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY" -X GET \
    -H "Content-Type: application/json" \
    "$RANCHER_API_URL/v3/clusterregistrationtokens?clusterId=$target_cluster_id")
registration_command=$(echo "$registration_command_response" | jq -r '.data[0].insecureNodeCommand')

echo $registration_command $ROLES | bash
