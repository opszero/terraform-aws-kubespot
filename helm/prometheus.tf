resource "helm_release" "prometheus" {
  chart            = "prometheus"
  name             = "prometheus"
  namespace        = "prometheus"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"

  set {
    name  = "podSecurityPolicy\\.enabled"
    value = true
  }

  set {
    name  = "server\\.persistentVolume\\.enabled"
    value = false
  }

  set {
    name = "server\\.resources"
    # You can provide a map of value using yamlencode
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "100Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "50Mi"
      }
    })
  }
}
