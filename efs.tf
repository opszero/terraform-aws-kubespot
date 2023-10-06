# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
module "iam_assumable_role_efs_csi" {
  count                  = var.efs_enabled ? 1 : 0
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                = "3.6.0"
  create_role            = true
  allow_self_assume_role = true
  role_name              = "${var.environment_name}-AmazonEFSCSIDriverPolicy"
  provider_url           = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns       = ["arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"]
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
