resource "helm_release" "cluster_autoscaler" {
  name = "cluster_autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  // App version should match the kubernetes version with in the chart
  // chart version 9.9.2 support kubernetes version 1.20
  // to get the chart version `helm search repo autoscaler/cluster-autoscaler --versions`
  version = "9.9.2"
  values = [<<EOF
autoDiscovery:
  clusterName: ${var.environment_name}
  awsRegion: us-east-1
  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}

cloudProvider: aws

replicaCount: 2

rbac:
 serviceAccount:
   name: cluster-autoscaler
   annotations:
     ## Enable if EKS IAM for SA is used
     eks.amazonaws.com/role-arn: "${module.iam_assumable_role_cluster_autoscaler.this_iam_role_arn}"
EOF
  ]
}
