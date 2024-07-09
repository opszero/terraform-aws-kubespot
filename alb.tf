module "iam_assumable_role_alb" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "5.40.0"
  create_role      = true
  role_name        = "${var.environment_name}-${local.alb_name}"
  provider_url     = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns = [aws_iam_policy.alb.arn]
  # namespace and service account name
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:${local.alb_name}"
  ]
  tags = local.tags
}

resource "helm_release" "aws_load_balancer" {
  count      = var.aws_load_balancer_controller_enabled ? 1 : 0
  name       = local.alb_name
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_version
  depends_on = [
    module.iam_assumable_role_alb,
    kubernetes_config_map.aws_auth
  ]
  wait = false

  values = [<<EOF
clusterName: ${var.environment_name}

region: ${data.aws_region.current.name}

vpcId: ${aws_vpc.vpc.id}

serviceAccount:
  controller:
    create: true
    name: ${local.alb_name}
    ## Enable if EKS IAM for SA is used
    annotations:
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_alb.iam_role_arn}"
EOF
  ]
}
