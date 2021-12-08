resource "aws_cloudformation_stack" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "${var.environment_name}-karpenter"

  parameters = {
    ClusterName = aws_eks_cluster.cluster.name
  }

  template_body = file("karpenter.yml")

}

module "iam_assumable_role_karpenter" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "3.6.0"
  create_role      = true
  role_name        = "${var.environment_name}-${var.karpenter_name}"
  provider_url     = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${aws_eks_cluster.cluster.name}"
  # namespace and service account name
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:${var.karpenter_name}",
    "system:node:{{EC2PrivateDNSName}}",
    "system:nodes",
    "system:bootstrappers"
  ]
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
  depends_on = [
    aws_cloudformation_stack.karpenter
  ]
}

resource "helm_release" "karpenter" {
  count            = var.karpenter_enabled ? 1 : 0
  name             = var.karpenter_name
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter/karpenter"
  version          = var.karpenter_version
  create_namespace = true
  namespace        = "karpenter"
  wait             = true
  values = [<<EOF
controller.clusterName = ${aws_eks_cluster.cluster.name}
controller.clusterEndpoint = ${aws_eks_cluster.cluster.endpoint}
EOF
  ]
  depends_on = [
    aws_cloudformation_stack.karpenter
  ]
}
