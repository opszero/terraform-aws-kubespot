locals {
  # Encryption
  cluster_encryption_config = {
    resources        = var.cluster_encryption_config
    provider_key_arn = aws_kms_key.cluster_secrets.arn
  }
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

  access_config {
    authentication_mode = var.cluster_authentication_mode
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

  bootstrap_self_managed_addons = var.eks_auto_mode_enabled == true ? false : true
  # Compute Config (conditional setup for Auto Mode)
  dynamic "compute_config" {
    for_each = var.eks_auto_mode_enabled ? [1] : []
    content {
      enabled       = true
      node_pools    = ["system"]
      node_role_arn = aws_iam_role.node.arn
    }
  }
  # Kubernetes Network Config (Auto Mode specific)
  dynamic "kubernetes_network_config" {
    for_each = var.eks_auto_mode_enabled ? [1] : []
    content {
      elastic_load_balancing {
        enabled = true
      }
    }
  }
  # Storage Config (Auto Mode specific)
  dynamic "storage_config" {
    for_each = var.eks_auto_mode_enabled ? [1] : []
    content {
      block_storage {
        enabled = true
      }
    }
  }

  enabled_cluster_log_types = var.cluster_logging

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy,
  ]

  tags = local.tags
}

resource "aws_eks_addon" "core" {
  for_each = toset(flatten([
    "kube-proxy",
    "vpc-cni",
    "coredns",
    "aws-ebs-csi-driver",
    var.s3_csi_driver_enabled ? ["aws-mountpoint-s3-csi-driver"] : [],
    var.efs_enabled ? ["aws-efs-csi-driver"] : [],
    var.cloudwatch_observability_enabled ? ["amazon-cloudwatch-observability"] : [],
  ]))
  configuration_values = lookup({
    "amazon-cloudwatch-observability" = var.cloudwatch_observability_config
  }, each.key, null)
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = each.key
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

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

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSComputePolicy" {
  count      = var.eks_auto_mode_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  count      = var.eks_auto_mode_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSNetworkingPolicy" {
  count      = var.eks_auto_mode_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  count      = var.eks_auto_mode_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.cluster.name
}

resource "helm_release" "calico" {
  count = var.calico_enabled ? 1 : 0

  name       = "calico"
  repository = "https://docs.tigera.io/calico/charts"
  chart      = "tigera-operator"
  version    = var.calico_version

  # Set Calico-specific configuration values
  set = [
    {
      name  = "kubernetesProvider"
      value = "EKS"
    }
  ]

  set = [
    {
      name  = "cni.type"
      value = "Calico"
    }
  ]

  set = [
    {
      name  = "calicoNetwork.bgp"
      value = "Disabled"
    }
  ]
}

resource "null_resource" "delete_aws_node" {
  count = var.calico_enabled ? 1 : 0

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch installation default --type='json' -p='[{"op": "replace", "path": "/spec/cni", "value": {"type":"Calico"} }]'
      kubectl delete daemonset -n kube-system aws-node
    EOT
  }
}
