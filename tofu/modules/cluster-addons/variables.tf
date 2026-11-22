variable "certificate_dns_names" {
  description = "DNS names for the TLS certificate"
  type        = list(string)
}

variable "longhorn_host" {
  description = "Hostname for the Longhorn UI"
  type        = string
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
