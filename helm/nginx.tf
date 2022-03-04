resource "helm_release" "nginx" {
  count = var.keda_enabled ? 1 : 0

  name       = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # values = [
  #   "${file("./nginx.yml")}"
  # ]

  set {
    name  = "controller.replicaCount"
    value = var.nginx_replica_count
  }
}
