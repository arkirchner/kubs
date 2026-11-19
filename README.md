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

Set `admin_password` for Longhorn's basic authentication in a private `tofu/environments/local/terraform.tfvars` file or via `TF_VAR_admin_password`. The local libvirt network uses `10.0.0.0/24`.

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

## Existing deployments

The cluster configuration came from the `kvm_cluster` playground. Deployments managed there still use their original state. Before running an apply here for an existing deployment, migrate that environment's state and review the plan. The prototype's libvirt storage pool uses an absolute host path, so moving the working directory can affect the plan.
