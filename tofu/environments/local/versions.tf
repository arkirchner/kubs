terraform {
  required_version = ">= 1.5.0"

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.9"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.5"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6.3"
    }
  }
}

provider "talos" {}

provider "libvirt" {
  uri = "qemu:///system"
}
