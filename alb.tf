resource "helm_release" "aws_load_balancer" {
  count      = var.aws_load_balancer_controller_enabled ? 1 : 0
  name       = var.alb_name
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
    name: ${var.alb_name}
    ## Enable if EKS IAM for SA is used
    annotations:
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_alb.this_iam_role_arn}"
EOF
  ]
}
