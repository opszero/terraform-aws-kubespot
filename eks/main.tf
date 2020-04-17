resource "aws_eks_cluster" "cluster" {
  name     = var.environment_name
  role_arn = aws_iam_role.cluster.arn

  version = var.cluster_version

  vpc_config {
    endpoint_private_access = var.cluster_private_access
    endpoint_public_access  = var.cluster_public_access
    public_access_cidrs     = var.cluster_public_access_cidrs

    security_group_ids = [aws_security_group.cluster.id]

    subnet_ids = flatten([
      aws_subnet.public.*.id,
      aws_subnet.private.*.id,
    ])
  }

  enabled_cluster_log_types = var.cluster_logging

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]

  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_eks_addon" "core" {
  for_each = toset([
    "kube-proxy",
    "vpc-cni",
    "coredns"
  ])

  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = each.key
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}


resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.environment_name}-workers"
  node_role_arn   = aws_iam_role.cluster.arn
  subnet_ids = flatten([
    aws_subnet.public.*.id,
    aws_subnet.private.*.id,
  ])

  disk_size      = var.nodes_disk_size
  instance_types = var.nodes_instance_types
  scaling_config {
    desired_size = var.nodes_desired_capacity
    max_size     = var.nodes_max_size
    min_size     = var.nodes_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cluster-AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "aws_caller_identity" "current" {
}
