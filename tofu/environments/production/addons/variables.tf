variable "kubeconfig_path" {
  description = "Path to the kubeconfig for this cluster"
  type        = string
  nullable    = false

  validation {
    condition     = fileexists(pathexpand(var.kubeconfig_path))
    error_message = "Provide the path to an existing kubeconfig for this cluster."
  }
}

variable "certificate_dns_names" {
  description = "DNS names for the TLS certificate"
  type        = list(string)
}

variable "longhorn_host" {
  description = "Hostname for the Longhorn UI"
  type        = string
}

variable "admin_htpasswd" {
  description = "Precomputed bcrypt htpasswd entry for Longhorn basic authentication"
  type        = string
  sensitive   = true
  nullable    = false
}
