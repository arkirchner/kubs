# Talos infrastructure

OpenTofu manages Talos infrastructure. Each root has its own OpenTofu state.

| Root | Purpose |
| --- | --- |
| `tofu/` | Single-VM libvirt smoke test. Boots Talos without bootstrapping Kubernetes. |
| `tofu/environments/local/` | Local Kubernetes cluster on libvirt with one control-plane VM, two worker VMs, and a self-signed certificate issuer. |
| `tofu/environments/production/` | Cluster configuration for existing Talos nodes, with a Let's Encrypt issuer. |
| `tofu/environments/local/addons/` and `tofu/environments/production/addons/` | Kubernetes add-ons for the corresponding cluster. |

Both environments use `tofu/modules/talos-cluster/` to bootstrap Talos and `tofu/modules/cluster-addons/` to manage Cilium, Gateway API, cert-manager, and Longhorn.

## Prerequisites

Run `direnv allow` at the repository root to load the Nix development shell. For local VMs, install and start libvirt and QEMU with KVM support, and make sure your user can connect to `qemu:///system`.

## Local cluster

The local libvirt network defaults to `10.0.0.0/24`. To use another subnet, set `libvirt_network_cidr`, `controlplane_ips`, and `worker_ips` together.

```bash
environment=tofu/environments/local
tofu -chdir="$environment" init
tofu -chdir="$environment" plan
tofu -chdir="$environment" apply
./tofu/setup_clients "$environment"
```

The helper prints paths to private, environment-specific client files. Pass them to `kubectl --kubeconfig` and `talosctl --talosconfig`. Example routing manifests are in `tofu/examples/`.

Continue with the add-on steps below to install Cilium and make Kubernetes nodes ready.

For the single-VM smoke test, use `tofu -chdir=tofu init` and `tofu -chdir=tofu apply`. Override its image with the `talos_image_url` variable.

## Production cluster

Supply the existing Talos node IPs in private bootstrap variables. Use `environment=tofu/environments/production` with the same bootstrap commands. In the production add-on variables, supply the certificate DNS names, Longhorn hostname, and admin htpasswd entry. For certificate issuance, point DNS at the Gateway and make it reachable on port 80 for the HTTP-01 challenge.

## Kubernetes add-ons

Set `admin_htpasswd` as described below. Set `kubeconfig_path` to the absolute kubeconfig path printed by `setup_clients`. Put these inputs and any add-on overrides in the private `addons/terraform.tfvars` under the selected environment.

```bash
tofu -chdir="$environment/addons" init
tofu -chdir="$environment/addons" plan
tofu -chdir="$environment/addons" apply
```

Use this root for routine add-on changes. When tearing down a cluster, remove the add-ons while the Kubernetes API is still accessible.

## Longhorn UI credentials

Generate a bcrypt entry with `nix shell .#htpasswd -c htpasswd -nB admin`. It prompts for the password and prints one `username:hash` line. Store that line in `admin_htpasswd` in the environment's private `addons/terraform.tfvars` or pass it through `TF_VAR_admin_htpasswd`. With an existing installation, reuse the current entry from the `auth-proxy-htpasswd` Secret in the `auth` namespace to preserve the password and avoid a Secret update. Remove the old `admin_username` and `admin_password` inputs.

## Existing deployments

The cluster configuration came from the `kvm_cluster` playground. Deployments managed there still use their original state.

The local cluster now uses libvirt provider 0.9, which changed the resource schema and state format. Use a fresh state for a new local deployment. To run it alongside a legacy cluster, use a separate checkout and choose a different cluster name and subnet. Before adopting an existing deployment, back up its state and disks, then re-import its libvirt resources under the new schema and review the plan for replacements. The storage pool uses an absolute host path, so moving the checkout can also affect the plan.

For an existing Talos cluster, use the Talos upgrade workflow for the OS and Kubernetes before changing their corresponding OpenTofu inputs. The version defaults in this repository are used to bootstrap new clusters. Run `tofu init` in each root before planning.

### Split an existing state

An existing cluster keeps its current Kubernetes objects by moving their state bindings into the add-on root before applying either root. Move any `certificate_dns_names` and `longhorn_host` overrides to `addons/terraform.tfvars` and configure the kubeconfig and htpasswd entry there.

For the default workspace with local state, run the following from the environment directory while no other OpenTofu operations are running. It prepares two state files in a private archive and leaves the active state available for comparison.

```bash
(
  set -euo pipefail
  umask 077
  test "$(tofu workspace show)" = default
  test -s terraform.tfstate
  test ! -e addons/terraform.tfstate
  mkdir -p .state-archive
  archive=$(mktemp -d .state-archive/addons.XXXXXXXX)
  cp terraform.tfstate "$archive/original.tfstate"
  cp "$archive/original.tfstate" "$archive/bootstrap.tfstate"
  tofu state list -state="$archive/bootstrap.tfstate" |
    grep -E '^module\.cluster\.(helm_release\.|kubernetes_[^.]+\.|kubectl_manifest\.|data\.http\.gateway_api_crd\[)' > "$archive/addresses"
  while IFS= read -r address; do
    tofu state mv -state="$archive/bootstrap.tfstate" -state-out="$archive/addons.tfstate" "$address" "$address"
  done < "$archive/addresses"
  printf 'Prepared state files in %s\n' "$archive"
)
```

Inspect both files with `tofu state list -state=FILE`. Verify that the live `terraform.tfstate` still matches `original.tfstate` with `cmp` and that the add-on root has no state yet. Install `bootstrap.tfstate` as `terraform.tfstate` and `addons.tfstate` as `addons/terraform.tfstate` using `install -m 600`. Keep the archive and review a plan in each root before applying. Discard any saved plans from before the split.

### Kubernetes resource addresses

If existing state still tracks the Kubernetes objects under the addresses below, back up the state before upgrading. For each listed address present in `tofu state list`, run `tofu state rm OLD_ADDRESS`, then `tofu import NEW_ADDRESS IMPORT_ID` from the environment’s add-on root. Complete the imports and review a new plan before applying. A fresh environment needs no state migration.

| Old address | New address | Import ID |
| --- | --- | --- |
| `module.cluster.kubernetes_namespace.longhorn` | `module.cluster.kubernetes_namespace_v1.longhorn` | `longhorn-system` |
| `module.cluster.kubernetes_namespace.auth` | `module.cluster.kubernetes_namespace_v1.auth` | `auth` |
| `module.cluster.kubernetes_secret.auth_proxy_htpasswd` | `module.cluster.kubernetes_secret_v1.auth_proxy_htpasswd` | `auth/auth-proxy-htpasswd` |
| `module.cluster.kubernetes_config_map.auth_proxy` | `module.cluster.kubernetes_config_map_v1.auth_proxy` | `auth/auth-proxy` |
| `module.cluster.kubernetes_deployment.auth_proxy` | `module.cluster.kubernetes_deployment_v1.auth_proxy` | `auth/auth-proxy` |
| `module.cluster.kubernetes_service.auth_proxy` | `module.cluster.kubernetes_service_v1.auth_proxy` | `auth/auth-proxy` |

## Provider upgrades

Each root tracks its provider selections in `.terraform.lock.hcl`. Run `tofu init -upgrade` in the affected root when intentionally updating providers, then review the lock file diff and the plan. CI checks formatting and validates all roots with their locks in read-only mode.
