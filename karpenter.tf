data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:${local.arn_env}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  count = var.karpenter_enabled ? 1 : 0

  role       = aws_iam_role.node.name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

module "iam_assumable_role_karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "${var.environment_name}-karpenter-controller"
  provider_url                  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  oidc_fully_qualified_subjects = ["system:serviceaccount:karpenter:karpenter"]
}

resource "aws_iam_role_policy" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.environment_name}-karpenter"
  role = module.iam_assumable_role_karpenter[0].iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "pricing:GetProducts"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "helm_release" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_karpenter[0].iam_role_arn
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.cluster.endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.node.name
  }
}

data "http" "karpenter_crd" {
  url = "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_version}/charts/karpenter/crds/karpenter.sh_provisioners.yaml"
}

resource "null_resource" "karpenter_crd" {
  count = var.karpenter_enabled ? 1 : 0

  triggers = {
    manifest_sha1 = "${sha1("${data.http.karpenter_crd.body}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.http.karpenter_crd.body}\nEOF"
  }

  depends_on = [
    helm_release.karpenter
  ]
}

# resource "null_resource" "karpenter_crd" {
#   count            = var.karpenter_enabled ? 1 : 0

#   triggers = {
#     manifest_sha1 = "${sha1("${data.http.karpenter_crd.body}")}"
#   }

#   provisioner "local-exec" {
#     command = "aws iam create-service-linked-role --aws-service-name spot.amazonaws.com"
#   }

#   depends_on = [
#     helm_release.karpenter
#   ]
# }
