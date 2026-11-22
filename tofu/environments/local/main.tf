module "cluster" {
  source = "../../modules/talos-cluster"

  cluster_name        = var.cluster_name
  talos_version       = var.talos_version
  kubernetes_version  = var.kubernetes_version
  controlplane_ips    = var.controlplane_ips
  worker_ips          = var.worker_ips
  ephemeral_disk_size = var.ephemeral_disk_size
  node_dependency     = libvirt_domain.node
}
