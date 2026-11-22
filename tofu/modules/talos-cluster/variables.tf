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
}

variable "node_dependency" {
  description = "Pass-through dependency to ensure VMs are created before Talos configuration is applied"
  type        = any
  default     = null
}

variable "cluster_issuer_spec" {
  description = "cert-manager ClusterIssuer spec (selfSigned for local, acme for production)"
  type        = any
}

variable "admin_htpasswd" {
  description = "Precomputed bcrypt htpasswd entry for Longhorn basic authentication"
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = can(regex("^[^:\r\n]+:\\$2[aby]\\$[0-9]{2}\\$[./A-Za-z0-9]{53}$", trimspace(var.admin_htpasswd)))
    error_message = "Use one bcrypt htpasswd entry in username:hash format."
  }
}
