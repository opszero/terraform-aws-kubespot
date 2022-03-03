resource "helm_release" "keda" {
  name       = "nginx"
  repository = "https://kedacore.github.io/charts"
  chart      = "kedacore/keda"
  namespace  = "keda"

  set {
    name  = "controller.replicaCount"
    value = var.nginx_replica_count
  }
}
