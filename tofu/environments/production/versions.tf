terraform {
  required_version = ">= 1.5.0"

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6.3"
    }
  }
}

provider "talos" {}
