data "aws_ssm_parameter" "amis" {
  for_each = {
    "BOTTLEROCKET_ARM_64"        = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}/arm64/latest/image_id",
    "BOTTLEROCKET_x86_64"        = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}/x86_64/latest/image_id",
    "BOTTLEROCKET_ARM_64_NVIDIA" = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}-nvidia/arm64/latest/image_id",
    "BOTTLEROCKET_x86_64_NVIDIA" = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}-nvidia/x86_64/latest/image_id",
    "AL2023_x86_64_STANDARD"     = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id",
    "AL2023_ARM_64_STANDARD"     = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/arm64/standard/recommended/image_id",
    "AL2023_x86_64_NEURON"       = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id",
    "AL2023_x86_64_NVIDIA"       = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/nvidia/recommended/image_id"
  }

  name = each.value
}
