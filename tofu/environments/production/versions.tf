terraform {
  required_version = ">= 1.5.0"

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "~> 6.7.41"
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

provider "ionoscloud" {
  # Configure via environment variables:
  #   IONOS_USERNAME
  #   IONOS_PASSWORD
  # Or via a variable:
  #   token = var.ionos_token
}
