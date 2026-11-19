locals {
  version = "1.20.5"
  # Keep the CRDs on the Gateway API version supported by this Cilium release.
  gateway_api_crd_version = "v1.6.3"
  gateway_api_crds = toset([
    "gatewayclasses",
    "gateways",
    "httproutes",
    "referencegrants",
    "grpcroutes",
    "backendtlspolicies",
    "tlsroutes"
  ])
}

data "http" "gateway_api_crd" {
  for_each = local.gateway_api_crds
  url      = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${local.gateway_api_crd_version}/config/crd/experimental/gateway.networking.k8s.io_${each.value}.yaml"
}

resource "kubectl_manifest" "gateway_api_crd" {
  depends_on        = [data.http.kubernetes_ready]
  for_each          = local.gateway_api_crds
  yaml_body         = data.http.gateway_api_crd[each.value].response_body
  server_side_apply = true
}

resource "helm_release" "cilium" {
  depends_on = [kubectl_manifest.gateway_api_crd]

  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = local.version
  namespace  = "kube-system"

  set = [
    { name = "ipam.mode", value = "kubernetes" },
    { name = "kubeProxyReplacement", value = "true" },
    { name = "securityContext.capabilities.ciliumAgent", value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,NET_BIND_SERVICE,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" },
    { name = "securityContext.capabilities.cleanCiliumState", value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" },
    { name = "cgroup.autoMount.enabled", value = "false" },
    { name = "cgroup.hostRoot", value = "/sys/fs/cgroup" },
    { name = "k8sServiceHost", value = "localhost" },
    { name = "k8sServicePort", value = "7445" },
    { name = "gatewayAPI.enabled", value = "true" },
    { name = "gatewayAPI.enableAlpn", value = "true" },
    { name = "gatewayAPI.enableAppProtocol", value = "true" },
    { name = "gatewayAPI.hostNetwork.enabled", value = "true" },
    { name = "envoy.enabled", value = "true" },
    { name = "envoy.securityContext.capabilities.keepCapNetBindService", value = "true" },
    { name = "envoy.securityContext.capabilities.envoy", value = "{NET_ADMIN,SYS_ADMIN,NET_BIND_SERVICE}" },
  ]
}

resource "helm_release" "cert_manager" {
  depends_on = [helm_release.cilium]

  name             = "cert-manager"
  repository       = "oci://quay.io/jetstack/charts"
  chart            = "cert-manager"
  version          = "v1.21.3"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    { name = "crds.enabled", value = "true" },
    { name = "config.enableGatewayAPI", value = "true" },
  ]
}

resource "kubectl_manifest" "cluster_issuer" {
  depends_on = [helm_release.cert_manager]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-issuer"
    }
    spec = var.cluster_issuer_spec
  })
}

resource "kubectl_manifest" "certificate" {
  depends_on = [kubectl_manifest.cluster_issuer]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "dns-certificates"
      namespace = "kube-system"
    }
    spec = {
      dnsNames   = var.certificate_dns_names
      secretName = "secret-dns-certificates"
      issuerRef = {
        name = "letsencrypt-issuer"
        kind = "ClusterIssuer"
      }
    }
  })
}

resource "kubectl_manifest" "gateway" {
  depends_on = [kubectl_manifest.certificate]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "cilium"
      namespace = "kube-system"
    }
    spec = {
      gatewayClassName = "cilium"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name      = "secret-dns-certificates"
                namespace = "kube-system"
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  })
}
