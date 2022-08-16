data "aws_iam_policy_document" "cluster_user" {
  statement {
    actions   = [
      "eks:AccessKubernetesApi",
      "eks:Describe*",
      "eks:List*",
    ]
    effect = "Allow"
    resources = [
      aws_eks_cluster.cluster.arn
    ]
  }
}

resource "aws_iam_role" "user_access_admin" {
  name = "${var.environment_name}-user-admin"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = data.aws_caller_identity.current.account_id
      }
      Condition = {}
    }]
    Version = "2012-10-17"
  })

  inline_policy {
    name   = "policy-8675309"
    policy = data.aws_iam_policy_document.cluster_user.json
  }

  tags = local.tags
}

resource "aws_iam_group" "user_access_admin" {
  name = "${var.environment_name}-user-admin"
}

resource "aws_iam_group_policy" "user_access_admin" {
  name  = "${var.environment_name}-user-admin"
  group = aws_iam_group.user_access_admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAssumeOrganizationAccountRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole",
        Resource = aws_iam_role.user_access_admin.arn
      },
    ]
  })
}

#Role and RoleBinding
resource "kubernetes_role" "default_eks_admins" {
  metadata {
    name      = "default:ad-eks-admins"
    namespace = "kube-system"
    labels = {
      sso_role = "eks-admins"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role_binding" "default_eks_admins" {
  metadata {
    name      = "eks-admins-binding"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.default_eks_admins.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = kubernetes_role.default_eks_admins.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role" "default_eks_readonly" {
  metadata {
    name      = "default:ad-eks-readonly"
    namespace = "kube-system"
    labels = {
      sso_role = "eks-readonly"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role_binding" "default_eks_readonly" {
  metadata {
    name      = "eks-readonly-binding"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.default_eks_readonly.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = kubernetes_role.default_eks_readonly.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role" "default_eks_developers" {
  metadata {
    name      = "default:ad-eks-developers"
    namespace = "kube-system"
    labels = {
      sso_role = "eks-developers"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["services", "deployments", "pods", "configmaps", "pods/log"]
    verbs      = ["get", "list", "watch", "update", "create", "patch"]
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role_binding" "default_eks_developers" {
  metadata {
    name      = "eks-dev-binding"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.default_eks_developers.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = kubernetes_role.default_eks_developers.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role" "default_eks_monitoring_admins" {
  metadata {
    name      = "default:ad-eks-monitoringadmins"
    namespace = "kube-system"
    labels = {
      sso_role = "eks-monitoringadmins"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_role_binding" "default_eks_monitoring_admins" {
  metadata {
    name      = "eks-monitoringadmins"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.default_eks_monitoring_admins.metadata[0].name
  }
  subject {
    kind      = "Group"
    name      = kubernetes_role.default_eks_monitoring_admins.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

#ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "eks_admins_binding" {
  metadata {
    name = "clusterrole-eks-admins-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    name      = "default:ad-eks-admins"
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}

resource "kubernetes_cluster_role_binding" "eks_readonly_binding" {
  metadata {
    name = "clusterrole-eks-readonly-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:aggregate-to-view"
  }
  subject {
    kind      = "Group"
    name      = "default:ad-eks-readonly"
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}
