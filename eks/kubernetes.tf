provider "kubernetes" {
  host                   = "${aws_eks_cluster.cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.cluster.token}"
  load_config_file       = false
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
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
