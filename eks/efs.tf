resource "helm_release" "aws_efs_csi_driver" {
  count = var.efs_enabled ? 1 : 0
  name  = "aws-efs-csi-driver"

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
      eks.amazonaws.com/role-arn: "${module.iam_assumable_role_admin[0].this_iam_role_arn}"
EOF
  ]
}
