resource "helm_release" "datadog" {
  count = var.datadog_api_key != "" ? 1 : 0

  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"

  namespace        = "datadog"
  create_namespace = true

  force_update  = true
  recreate_pods = true

  values = concat(
    [var.datadog_values == "" ? "${file("${path.module}/datadog.yml")}" : var.datadog_values],
  var.datadog_values_extra)

  set {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }
}
