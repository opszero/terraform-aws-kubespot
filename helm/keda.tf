resource "helm_release" "keda" {
  count = var.keda_enabled ? 1 : 0

  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  recreate_pods    = true
}
