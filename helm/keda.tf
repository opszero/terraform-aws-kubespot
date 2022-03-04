resource "helm_release" "keda" {
  count = var.keda_enabled ? 1 : 0

  name             = "nginx"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
}
