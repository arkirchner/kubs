module "cluster" {
  source = "../../../modules/cluster-addons"

  certificate_dns_names = var.certificate_dns_names
  longhorn_host         = var.longhorn_host
  admin_htpasswd        = var.admin_htpasswd
  cluster_issuer_spec = {
    acme = {
      server = "https://acme-v02.api.letsencrypt.org/directory"
      privateKeySecretRef = {
        name = "letsencrypt-issuer-key"
      }
      solvers = [
        {
          http01 = {
            gatewayHTTPRoute = {
              parentRefs = [
                {
                  name      = "cilium"
                  namespace = "kube-system"
                  kind      = "Gateway"
                }
              ]
            }
          }
        }
      ]
    }
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
