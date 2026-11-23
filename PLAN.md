# Production deployment plan for EuroNodes

Run Talos and Kubernetes on three existing EuroNodes VPSs. Use all three as schedulable control-plane nodes, with no dedicated workers. Three etcd members can maintain quorum with one node down.

Create the private VLAN, attach the VPSs, and boot the Talos ISO through the EuroNodes panel. EuroNodes currently lists no public Terraform provider. Use OpenTofu to configure Talos on the existing machines and to manage Kubernetes add-ons through a separate root. [EuroNodes API](https://kb.euronodes.com/api/) · [Custom ISO installation](https://kb.euronodes.com/vm/install-from-iso/)

## Confirm before deployment

- Confirm that all three VPSs are in the same EuroNodes location. The private VLAN is local to a single location. If the nodes are split across locations, revisit the networking and endpoint design before installing Talos. [EuroNodes private VLAN](https://kb.euronodes.com/network/private-network/)
- Record each VPS's vCPU count, RAM, available disk, and NIC MAC addresses. Target at least 2 vCPUs and 4 GiB RAM per node for light workloads. Talos lists 2 cores and 2 GiB as the control-plane minimum. If only one VPS meets the control-plane requirements, use it as the control plane and the other two as workers. That layout has a single point of failure for the Kubernetes API. [Talos system requirements](https://docs.siderolabs.com/talos/v1.14/getting-started/system-requirements)
- Back up any existing VPS data needed after the Talos installation. Confirm console access and pick a private subnet that does not overlap with the admin VPN or Kubernetes pod and service networks.

## Private network

| Purpose | Example address |
| --- | --- |
| EuroNodes VLAN | `10.73.0.0/24` |
| Control-plane nodes | `10.73.0.11`, `10.73.0.12`, `10.73.0.13` |
| Shared Kubernetes API endpoint | `https://10.73.0.10:6443` |
| Talos administration | Individual node IPs over the admin VPN |

Give the second NIC on each VPS a static address. EuroNodes supplies no DHCP on the private VLAN. Keep the default internet route on the public NIC. Use the private subnet for kubelet node IPs, etcd, and Cilium node-to-node traffic. EuroNodes specifies a private MTU of 1400. Configure Cilium for that underlay and verify cross-node traffic with larger packets. [EuroNodes private VLAN](https://kb.euronodes.com/network/private-network/) · [Cilium Helm settings](https://docs.cilium.io/en/stable/helm-reference/)

Make the Kubernetes API reachable over a Talos VIP on the VLAN. Use the individual node IPs for the Talos API so recovery remains possible if etcd or the VIP is down. Establish an admin VPN route that works independently of Kubernetes. Keep management and cluster ports private on both IPv4 and IPv6. [Talos shared IP](https://docs.siderolabs.com/talos/v1.14/networking/advanced/vip) · [EuroNodes firewall rules](https://kb.euronodes.com/vm/bulk_firewall_rules/)

## Changes to this repository

1. Update the [production bootstrap root](tofu/environments/production/) to accept an explicit Kubernetes API endpoint and per-node machine configuration patches. The [Talos module](tofu/modules/talos-cluster/main.tf) currently points the endpoint at the first control-plane IP.
2. Set `controlplane_ips` to the three private node addresses and `worker_ips = []`. The module already enables workload scheduling on control planes for this layout. Configure the private NIC by MAC address and restrict kubelet and etcd address selection to the VLAN subnet.
3. Add a minimal option to the [production add-on root](tofu/environments/production/addons/). Start with Cilium and the cluster's CoreDNS. Make Gateway API, cert-manager, Longhorn, and its auth proxy opt-in. For a first stateful app, confirm whether node-local storage and restore from backup meet its needs. Data on a local volume stays tied to its node.

## Rollout and acceptance checks

1. **Prove the network on one VPS.** Attach the VLAN, verify the NIC and default route, and confirm that the admin workstation can reach the Talos maintenance API privately. Keep console access available and repeat the checks on the other two VPSs.
2. **Bootstrap Talos.** Review the production bootstrap plan, apply the machine configurations, bootstrap etcd once, and export the kubeconfig. Check that the API responds at the private VIP.
3. **Install Cilium.** Run the production add-on plan using the exported kubeconfig. Confirm all three nodes are `Ready`, their `InternalIP` values are on the VLAN, and pods can resolve DNS and communicate across nodes.
4. **Test recovery.** Reboot the VIP owner and verify that the Kubernetes API recovers through another control-plane node. Keep an etcd snapshot and workload backups off-cluster. Upgrade one node at a time.
