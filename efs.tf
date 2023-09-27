resource "helm_release" "aws_efs_csi_driver" {
  count     = var.efs_enabled ? 1 : 0
  name      = "aws-efs-csi-driver"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  depends_on = [
    module.iam_assumable_role_admin,
    kubernetes_config_map.aws_auth
  ]

  wait = false

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

resource "aws_iam_role_policy_attachment" "node-EFS" {
  policy_arn = aws_iam_policy.efs_policy.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_policy" "efs_policy" {
  name        = "${var.environment_name}-efs-policy"
  description = "EKS cluster policy for EFS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF
}

module "iam_assumable_role_admin" {
  count            = var.efs_enabled ? 1 : 0
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "5.30.0"
  create_role      = true
  role_name        = "${var.environment_name}-efs-driver"
  provider_url     = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
  role_policy_arns = [aws_iam_policy.efs_policy.arn]
  # namespace and service account name
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
