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

module "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.6.0"

  cluster_name = var.environment_name

  irsa_oidc_provider_arn          = aws_iam_openid_connect_provider.cluster.arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  irsa_use_name_prefix            = false

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
    value = module.karpenter[0].irsa_arn
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

resource "aws_iam_policy" "node_role_karpenter" {
  count       = var.karpenter_enabled ? 1 : 0
  name        = "${var.environment_name}-karpenter-policy"
  description = "Karpenter delete launch template"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteLaunchTemplate"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "node_role_karpenter" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = aws_iam_policy.node_role_karpenter[0].arn
  role       = aws_iam_role.node.name
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
