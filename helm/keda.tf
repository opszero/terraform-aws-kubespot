resource "helm_release" "keda" {
  name       = "nginx"
  repository = "https://kedacore.github.io/charts"
  chart      = "kedacore/keda"
  namespace  = "keda"
}
