provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.environment_name
}
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<CONFIGMAPAWSAUTH
- rolearn: ${aws_iam_role.node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_AD-EKS-Admins_b2abd90bad1696ac
      username: adminuser:{{SessionName}}
      groups:
        - default:ad-eks-admins
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_AD-EKS-ReadOnly_2c5eb8d559b68cb5
  username: readonlyuser:{{SessionName}}
  groups:
    - default:ad-eks-readonly
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_AD-EKS-Developers_ac2b0d744059fcd6
  username: devuser:{{SessionName}}
  groups:
    - default:ad-eks-developers
- rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_AD-EKS-Monitoring-Admins_ac2b0d744059fcd6
  username: monitoringadminuser:{{SessionName}}
  groups:
    - default:ad-eks-monitoring-admins
CONFIGMAPAWSAUTH

    mapUsers = <<CONFIGMAPAWSUSERS
%{for user in var.iam_users~}
- userarn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}
  username: ${user}
  groups:
    - system:masters
%{endfor~}
CONFIGMAPAWSUSERS
  }
}
