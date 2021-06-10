#Role and RoleBinding
resource "kubernetes_role" "default_eks_admins" {
  metadata {
    name = "default:ad-eks-admins"
    namespace = "default"
    labels = {
      sso_role = "eks-admins"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "default_eks_admins" {
  metadata {
    name      = "eks-admins-binding"
    namespace = "default"
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
}

resource "kubernetes_role" "default_eks_readonly" {
  metadata {
    name = "default:ad-eks-readonly"
    namespace = "default"
    labels = {
      sso_role = "eks-readonly"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "default_eks_readonly" {
  metadata {
    name      = "eks-readonly-binding"
    namespace = "default"
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
}

resource "kubernetes_role" "default_eks_developers" {
  metadata {
    name = "default:ad-eks-developers"
    namespace = "default"
    labels = {
      sso_role = "eks-developers"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["services","deployments", "pods", "configmaps", "pods/log"]
    verbs      = ["get", "list", "watch", "update", "create", "patch"]
  }
}

resource "kubernetes_role_binding" "default_eks_developers" {
  metadata {
    name      = "eks-dev-binding"
    namespace = "default"
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
}

resource "kubernetes_role" "default_eks_monitoring_admins" {
  metadata {
    name = "default:ad-eks-monitoringadmins"
    namespace = "default"
    labels = {
      sso_role = "eks-monitoringadmins"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "default_eks_monitoring_admins" {
  metadata {
    name      = "eks-monitoringadmins"
    namespace = "default"
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
}
