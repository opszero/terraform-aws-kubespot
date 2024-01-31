data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

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
    command = [
      "kubectl apply -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/${var.karpenter_version}/pkg/apis/crds/karpenter.sh_nodepools.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/${var.karpenter_version}/pkg/apis/crds/karpenter.sh_nodeclaims.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/${var.karpenter_version}/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml",
    ]
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
