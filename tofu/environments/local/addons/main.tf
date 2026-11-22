module "cluster" {
  source = "../../../modules/cluster-addons"

  certificate_dns_names = var.certificate_dns_names
  longhorn_host         = var.longhorn_host
  admin_htpasswd        = var.admin_htpasswd
  cluster_issuer_spec = {
    selfSigned = {}
  }
}

locals {
  kubeconfig_path = pathexpand(var.kubeconfig_path)
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "kubectl" {
  config_path = local.kubeconfig_path
}
