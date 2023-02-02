data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

provider "aws" {
  profile = var.aws_profile
  region  = "us-east-1"
  alias   = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "aws_iam_role_policy" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.environment_name}-node-karpenter"
  role = aws_iam_role.node.id

  policy = data.aws_iam_policy_document.karpenter[0].json
}

# Copied from https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v19.6.0/modules/karpenter/main.tf
data "aws_iam_policy_document" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  statement {
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]

    resources = ["*"]

    # TODO
    # condition {
    #   test     = "StringEquals"
    #   variable = "ec2:ResourceTag/KubespotEnvironment"
    #   values   = [var.environment_name]
    # }
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:${local.partition}:ec2:*:${local.account_id}:launch-template/*",
    ]

    # TODO
    # condition {
    #   test     = "StringEquals"
    #   variable = "ec2:ResourceTag/KubespotEnvironment"
    #   values   = [var.environment_name]
    # }
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:${local.partition}:ec2:*::image/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:instance/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:spot-instances-request/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:security-group/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:volume/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:network-interface/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:subnet/*",
    ]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/aws/service/*"]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.node.arn]
  }
}

module "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.6.0"

  cluster_name = var.environment_name

  irsa_oidc_provider_arn          = aws_iam_openid_connect_provider.cluster.arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  irsa_tag_key                    = "KubespotEnvironment"

  create_iam_role = false
  iam_role_arn    = aws_iam_role.node.arn

  enable_spot_termination = false

  tags = local.tags
}

resource "helm_release" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_version

  set {
    name  = "settings.aws.clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = aws_eks_cluster.cluster.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter[0].instance_profile_name
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
    command = "kubectl replace -f https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_version}/pkg/apis/crds/karpenter.sh_provisioners.yaml"
  }

  depends_on = [
    helm_release.karpenter
  ]
}

resource "null_resource" "karpenter_awsnodetemplates_crd" {
  count = var.karpenter_enabled ? 1 : 0

  triggers = {
    manifest_sha1 = "${sha1("${data.http.karpenter_crd.body}")}"
  }

  provisioner "local-exec" {
    command = "kubectl replace -f https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_version}/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml"
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
