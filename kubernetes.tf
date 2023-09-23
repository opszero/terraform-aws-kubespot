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
- rolearn: ${aws_iam_role.fargate.arn}
  username: system:node:{{SessionName}}
  groups:
    - system:bootstrappers
    - system:nodes
    - system:node-proxier
%{for role, groups in var.iam_roles~}
- rolearn: ${role}
  username: adminuser:{{SessionName}}
  groups:
     ${yamlencode(groups.rbac_groups)}
%{endfor~}
CONFIGMAPAWSAUTH

    mapUsers = <<CONFIGMAPAWSUSERS
%{for user, groups in var.iam_users~}
- userarn: arn:${local.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${user}
  username: ${user}
  groups:
     ${yamlencode(groups.rbac_groups)}
%{endfor~}
CONFIGMAPAWSUSERS
  }
}
