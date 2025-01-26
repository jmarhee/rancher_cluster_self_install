#!/bin/bash

# Variables
export CLUSTER_NAME="$(hostname)"
export ARGOCD_FQDN="argocd.$CLUSTER_NAME.organization.tld"
export K3S_VERSION="v1.30.7+k3s1"

#Build Config
export ADDITIONAL_MANIFESTS="$(awk '{printf "%s\\n", $0}' additional_manifests.yaml)"
ROLES="--etcd --controlplane --worker"
CLUSTER_CONFIG=$(cat cluster_config_template.json) # | awk '{print}' ORS='" ')
RENDERED_CONFIG=$(echo $CLUSTER_CONFIG | envsubst)

# Create a new K3s cluster in Rancher
curl --insecure -u "$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY" -X POST \
  -H "Content-Type: application/json" \
  -d "$RENDERED_CONFIG" \
  "$RANCHER_API_URL/v1/provisioning.cattle.io.clusters"

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

# Wait for provisioning and record population
sleep 10

# Request insecureNodeToken and append roles.
registration_command_response=$(curl --insecure -s -u "$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY" -X GET \
    -H "Content-Type: application/json" \
    "$RANCHER_API_URL/v3/clusterregistrationtokens?clusterId=$target_cluster_id")
registration_command=$(echo "$registration_command_response" | jq -r '.data[0].insecureNodeCommand')

echo $registration_command $ROLES | bash
