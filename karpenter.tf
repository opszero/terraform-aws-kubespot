data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

module "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.8.5"

  cluster_name = var.environment_name

  enable_irsa                     = true
  irsa_oidc_provider_arn          = aws_iam_openid_connect_provider.cluster.arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = true
  iam_role_name   = "${var.environment_name}-karpenter-controller"

  create_node_iam_role          = false
  node_iam_role_use_name_prefix = false
  node_iam_role_arn             = aws_iam_role.node.arn

  create_instance_profile = true
  create_access_entry     = false

  queue_name = "${var.environment_name}-spot-termination"

  tags = local.tags
}

resource "helm_release" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.36.1"

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.cluster.name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.cluster.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter[0].iam_role_arn
  }

  depends_on = [
    helm_release.karpenter_crd
  ]
}

resource "helm_release" "karpenter_crd" {
  count = var.karpenter_enabled ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "0.36.1"
}
