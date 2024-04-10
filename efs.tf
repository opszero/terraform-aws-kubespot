# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
module "iam_assumable_role_efs_csi" {
  count            = var.efs_enabled ? 1 : 0
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "5.38.0"
  create_role      = true
  role_name        = "${var.environment_name}-AmazonEFSCSIDriverPolicy"
  provider_url     = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"]
  # namespace and service account name
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:efs-csi-controller-sa",
    "system:serviceaccount:kube-system:efs-csi-node-sa",
    "system:serviceaccount:kube-system:efs-csi-*",
  ]
  oidc_fully_qualified_audiences = [
    "sts.amazonaws.com"
  ]
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "kubernetes_service_account" "efs_csi_controller_sa" {
  count = var.efs_enabled ? 1 : 0

  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_efs_csi[0].iam_role_arn
    }
  }
}

resource "kubernetes_service_account" "efs_csi_node_sa" {
  count = var.efs_enabled ? 1 : 0

  metadata {
    name      = "efs-csi-node-sa"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_efs_csi[0].iam_role_arn
    }
  }
}
