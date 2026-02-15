# Talos Single-Node Cluster with OpenTofu

This repo sets up a single-node Talos Kubernetes cluster locally first, then applies a similar configuration to a VPS. All infrastructure is managed with OpenTofu.

## Local Test Setup (VM)

The local test environment uses libvirt to boot a single Talos VM from an official QCOW2 image. Talos config and Kubernetes bootstrap will be added next.

### Prerequisites

- nix + direnv
- libvirt + qemu
- OpenTofu (provided by `direnv` via the flake)

### Quick Start

```bash
direnv allow
tofu -chdir=tofu init
tofu -chdir=tofu apply
```

## Plan

1. Local single-node VM with libvirt (this step).
2. Add Talos provider to generate machine config and apply it to the VM.
3. Bootstrap Kubernetes and export kubeconfig.
4. Add OpenTofu-managed Helm charts.
5. Mirror the same configuration for the VPS (single-node cluster).

## Notes

- The VM image URL can be overridden with `-var="talos_image_url=..."`.
- State files are ignored by git; use `.tfvars` files for local overrides.
