data "aws_region" "current" {
  provider = aws
}

resource "helm_release" "cluster_autoscaler" {
  name = var.cluster_autoscaler_name
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version = var.cluster_autoscaler_version
  namespace = "kube-system"
  values = [<<EOF
autoDiscovery:
  clusterName: ${var.environment_name}
  awsRegion: ${data.aws_region.current.name}
  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/${var.environment_name}

cloudProvider: aws

replicaCount: 2

rbac:
 serviceAccount:
   name: ${var.cluster_autoscaler_name}
   annotations:
     ## Enable if EKS IAM for SA is used
     eks.amazonaws.com/role-arn: "${module.iam_assumable_role_cluster_autoscaler.this_iam_role_arn}"
EOF
  ]
}
