# Talos infrastructure

OpenTofu manages Talos infrastructure. Each root has its own OpenTofu state.

| Root | Purpose |
| --- | --- |
| `tofu/` | Single-VM libvirt smoke test. Boots Talos without bootstrapping Kubernetes. |
| `tofu/environments/local/` | Local Kubernetes cluster on libvirt with one control-plane VM, two worker VMs, and a self-signed certificate issuer. |
| `tofu/environments/production/` | Cluster configuration for existing Talos nodes, with a Let's Encrypt issuer. IONOS VM provisioning is still a stub. |

Both cluster environments use `tofu/modules/talos-cluster/` for Talos bootstrap, Cilium, Gateway API, cert-manager, and Longhorn.

## Prerequisites

Run `direnv allow` at the repository root to load the Nix development shell. For local VMs, install and start libvirt and QEMU with KVM support, and make sure your user can connect to `qemu:///system`.

## Local cluster

Set `admin_htpasswd` for the Longhorn UI as described below. The local libvirt network defaults to `10.0.0.0/24`. To use another subnet, set `libvirt_network_cidr`, `controlplane_ips`, and `worker_ips` together.

```bash
tofu -chdir=tofu/environments/local init
tofu -chdir=tofu/environments/local plan
tofu -chdir=tofu/environments/local apply
./tofu/setup_clients tofu/environments/local
```

The helper prints paths to private, environment-specific client files. Pass them to `kubectl --kubeconfig` and `talosctl --talosconfig`. Example routing manifests are in `tofu/examples/`.

For the single-VM smoke test, use `tofu -chdir=tofu init` and `tofu -chdir=tofu apply`. Override its image with the `talos_image_url` variable.

## Production cluster

Provide the existing Talos node IPs, certificate DNS names, Longhorn hostname, and admin credentials using private variables. Use `tofu/environments/production` as the OpenTofu root and as the argument to `tofu/setup_clients`. For certificate issuance, point DNS at the Gateway and make it reachable on port 80 for the HTTP-01 challenge.

## Longhorn UI credentials

Generate a bcrypt entry with `nix shell .#htpasswd -c htpasswd -nB admin`. It prompts for the password and prints one `username:hash` line. Store that line in `admin_htpasswd` in the environment's private `terraform.tfvars` or pass it through `TF_VAR_admin_htpasswd`. With an existing installation, reuse the current entry from the `auth-proxy-htpasswd` Secret in the `auth` namespace to preserve the password and avoid a Secret update. Remove the old `admin_username` and `admin_password` inputs.

## Existing deployments

The cluster configuration came from the `kvm_cluster` playground. Deployments managed there still use their original state.

The local cluster now uses libvirt provider 0.9, which changed the resource schema and state format. Use a fresh state for a new local deployment. To run it alongside a legacy cluster, use a separate checkout and choose a different cluster name and subnet. Before adopting an existing deployment, back up its state and disks, then re-import its libvirt resources under the new schema and review the plan for replacements. The storage pool uses an absolute host path, so moving the checkout can also affect the plan.

For an existing Talos cluster, use the Talos upgrade workflow for the OS and Kubernetes before changing their corresponding OpenTofu inputs. The version defaults in this repository are used to bootstrap new clusters. Run `tofu init -upgrade` in a previously initialized root to pick up the new providers before planning.

### Kubernetes resource addresses

If existing state still tracks the Kubernetes objects under the addresses below, back up the state before upgrading. For each listed address present in `tofu state list`, run `tofu state rm OLD_ADDRESS`, then `tofu import NEW_ADDRESS IMPORT_ID` from the environment that manages the object. Complete the imports and review a new plan before applying. A fresh environment needs no state migration.

| Old address | New address | Import ID |
| --- | --- | --- |
| `module.cluster.kubernetes_namespace.longhorn` | `module.cluster.kubernetes_namespace_v1.longhorn` | `longhorn-system` |
| `module.cluster.kubernetes_namespace.auth` | `module.cluster.kubernetes_namespace_v1.auth` | `auth` |
| `module.cluster.kubernetes_secret.auth_proxy_htpasswd` | `module.cluster.kubernetes_secret_v1.auth_proxy_htpasswd` | `auth/auth-proxy-htpasswd` |
| `module.cluster.kubernetes_config_map.auth_proxy` | `module.cluster.kubernetes_config_map_v1.auth_proxy` | `auth/auth-proxy` |
| `module.cluster.kubernetes_deployment.auth_proxy` | `module.cluster.kubernetes_deployment_v1.auth_proxy` | `auth/auth-proxy` |
| `module.cluster.kubernetes_service.auth_proxy` | `module.cluster.kubernetes_service_v1.auth_proxy` | `auth/auth-proxy` |
