variable "cluster_name" {
  type        = string
  description = "Name for the local Talos VM."
  default     = "talos-test"
}

variable "libvirt_uri" {
  type        = string
  description = "libvirt connection URI."
  default     = "qemu:///system"
}

variable "libvirt_pool" {
  type        = string
  description = "libvirt storage pool to use."
  default     = "default"
}

variable "libvirt_network" {
  type        = string
  description = "libvirt network to attach the VM to."
  default     = "default"
}

variable "talos_image_url" {
  type        = string
  description = "Talos QCOW2 image URL to boot from."
  default     = "https://factory.talos.dev/image/d9ff89777e246792e7642abd3220a616afb4e49822382e4213a2e528ab826fe5/v1.14.6/metal-amd64.qcow2"
}

variable "memory_mb" {
  type        = number
  description = "VM memory in MB."
  default     = 4096
}

variable "vcpu" {
  type        = number
  description = "Number of virtual CPUs."
  default     = 2
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB."
  default     = 20
}
