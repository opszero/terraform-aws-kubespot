resource "kubernetes_namespace" "amazon_cloudwatch" {
  count = var.cloudwatch_pod_logs_enabled ? 1 : 0

  metadata {
    name = "amazon-cloudwatch"
  }
}

resource "kubernetes_config_map" "fluent_bit_cluster_info" {
  count = var.cloudwatch_pod_logs_enabled ? 1 : 0

  metadata {
    name      = "fluent-bit-cluster-info"
    namespace = "amazon-cloudwatch"
  }

  data = {
    "cluster.name" = aws_eks_cluster.cluster.name
    "http.server"  = "On"
    "http.port"    = 2020
    "read.head"    = "Off"
    "read.tail"    = "On"
    "logs.region"  = data.aws_region.current.name
  }
}
