resource "helm_release" "datadog" {
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"

  namespace        = "datadog"
  create_namespace = true

  values = [
    var.datadog_values == "" ? "${file("${path.module}/datadog.yml")}" : var.datadog_values
  ]

  set {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }
}
