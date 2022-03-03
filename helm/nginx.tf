resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx/ingress-nginx"

  values = [
    "${file("nginx.yaml")}"
  ]

  set {
    name  = "controller.replicaCount"
    value = var.nginx_replica_count
  }
}
