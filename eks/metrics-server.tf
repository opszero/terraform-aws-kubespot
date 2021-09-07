resource "helm_release" "metrics-server" {
  count      = var.metrics_server_enabled ? 1 : 0
  name       = "metrics-server"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"
  wait       = false
}
