variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "talos_version" {
  description = "Talos Linux version"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "controlplane_ips" {
  description = "IP addresses for control plane nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "IP addresses for worker nodes"
  type        = list(string)
}

variable "ephemeral_disk_size" {
  description = "Size of the EPHEMERAL volume on worker system disks"
  type        = string
}

variable "node_dependency" {
  description = "Pass-through dependency to ensure VMs are created before Talos configuration is applied"
  type        = any
  default     = null
}
