resource "kubernetes_namespace" "amazon_cloudwatch" {
  count = var.enable_pods_logs_to_cloudwatch ? 1 : 0

  metadata {
    name = "amazon-cloudwatch"
  }
}

resource "kubernetes_config_map" "fluent_bit_cluster_info" {
  count = var.enable_pods_logs_to_cloudwatch ? 1 : 0

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

data "http" "fluent_bit_yaml" {
  url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/k8s/${local.eks_pod_logs_cloudwatch_fluent_bit_version}/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
}


resource "null_resource" "eks_pod_cloudwatch" {
  count = var.enable_pods_logs_to_cloudwatch ? 1 : 0

  triggers = {
    manifest_sha1 = sha1(data.http.fluent_bit_yaml.body)
  }

  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/k8s/${local.eks_pod_logs_cloudwatch_fluent_bit_version}/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml"
  }

  depends_on = [
    kubernetes_namespace.amazon_cloudwatch,
    kubernetes_config_map.fluent_bit_cluster_info
  ]
}
