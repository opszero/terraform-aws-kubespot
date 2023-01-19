data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:${local.arn_env}:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
  version = "18.31.0"

  cluster_name = var.environment_name

  irsa_oidc_provider_arn          = aws_iam_openid_connect_provider.cluster.arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = module.iam_assumable_role_karpenter[0].iam_role_arn
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

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter[0].queue_name
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
