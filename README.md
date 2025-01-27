# K3s Self-Install Script

Modify the `cluster_config_template.json` for any installation preferences.

Modify `additional_manifests.yaml` for any YAML to be run on cluster installation.

This script, when run on a new host, can request a new `Cluster` be provisioned in Rancher Manager, and then request the cluster registration token and install script required to install K3s on the requesting machine.

## Setup

You will need the following variables either set in the environment, or in the script:

```bash
RANCHER_API_URL="https://<your rancher URL>" # Do not include a /v1 or /v3 uri
RANCHER_ACCESS_KEY="token-xxxxx"
RANCHER_SECRET_KEY="xxxxxxxxxxxxx"
```
and the `K3S_VERSION` desired.

### System Packages Required

The host system must have `curl` and `jq` installed.

## Additional Manifests

It is recommended that the manifests included be managed Helm charts using the [K3s Helm Controller](https://docs.k3s.io/helm#using-the-helm-crd)

## Extending

The base template includes Nginx-Ingress and ArgoCD, and configures an Ingress.

Set the `ARGOCD_FQDN` environment variable to something like "argocd.$CLUSTER_NAME.organization.tld" in the script to configure the Ingress.

## Troubleshooting

To check errors in API actions with provisioning or requesting tokens, check the Rancher Webhook logs:

```bash
kubectl logs -n cattle-system -l app=rancher-webhook
```
on the management server.

For issues with K3s installation, check the `rancher-system-agent` service for any issues reaching Rancher or applying the plan:

```bash
systemctl status rancher-system-agent
systemctl status k3s
```

and the `cattle-cluster-agent` pod logs in the `cattle-system` namespace, if the installation was successful, but Rancher has not registered the machine.
