locals {
  # Encryption
  cluster_encryption_config = {
    resources        = var.cluster_encryption_config
    provider_key_arn =  aws_kms_key.cluster.arn
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/eks/${var.environment_name}/cluster"
  retention_in_days = 30
  tags              =  local.tags
  kms_key_id        = aws_kms_key.cloudwatch_log.arn
}


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

  dynamic "encryption_config" {
    for_each = [local.cluster_encryption_config]
    content {
      resources = lookup(encryption_config.value, "resources")
      provider {
        key_arn = lookup(encryption_config.value, "provider_key_arn")
      }
    }
  }
  enabled_cluster_log_types = var.cluster_logging

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]

  tags = local.tags
}

resource "aws_eks_addon" "core" {
  for_each = toset([
    "kube-proxy",
    "vpc-cni",
    "coredns",
    "aws-ebs-csi-driver",
  ])

  cluster_name      = aws_eks_cluster.cluster.name
  addon_name        = each.key
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    kubernetes_config_map.aws_auth,
    aws_autoscaling_group.asg_nodes,
  ]
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_role" "cluster" {
  name = "${var.environment_name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}
