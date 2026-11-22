variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "production"
}

variable "talos_version" {
  description = "Talos Linux version"
  type        = string
  default     = "v1.14.6"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.37.2"
}

variable "controlplane_ips" {
  description = "IP addresses for control plane nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "IP addresses for worker nodes"
  type        = list(string)
}

variable "certificate_dns_names" {
  description = "DNS names for the TLS certificate"
  type        = list(string)
}

variable "longhorn_host" {
  description = "Hostname for the Longhorn UI"
  type        = string
}

variable "ephemeral_disk_size" {
  description = "Size of the EPHEMERAL volume on worker system disks"
  type        = string
  default     = "10GB"
}

variable "admin_htpasswd" {
  description = "Precomputed bcrypt htpasswd entry for Longhorn basic authentication"
  type        = string
  sensitive   = true
  nullable    = false
}
