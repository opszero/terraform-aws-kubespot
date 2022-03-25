
resource "helm_release" "nginx" {
  count = var.nginx_enabled ? 1 : 0

  name             = "nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "nginx"
  create_namespace = true

  values = [
    "${file("${path.module}/nginx.yml")}"
  ]

  set {
    name  = "controller.replicaCount"
    value = var.nginx_replica_count
  }
}
