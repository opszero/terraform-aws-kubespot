//provider "helm" {
//  count = var.efs_enabled ? 1 : 0
//  kubernetes {
//    config_path = "~/.kube/config"
//  }
//}
//
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  count = var.efs_enabled ? 1 : 0
  name       = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  depends_on = [module.iam_assumable_role_admin]

  values = [<<EOF
image:
  repository: 602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver

serviceAccount:
  controller:
    create: true
    name: efs-csi-controller-sa
    ## Enable if EKS IAM for SA is used
    annotations:
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin[0].this_iam_role_name}"
EOF
  ]
}
