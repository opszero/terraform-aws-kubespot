
provider "helm" {
  kubernetes {
    host                   = "${aws_eks_cluster.cluster.endpoint}"
    cluster_ca_certificate = "${base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)}"
    token                  = "${data.aws_eks_cluster_auth.cluster.token}"
    load_config_file       = false
  }

  install_tiller  = true
  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
}

resource "kubernetes_service_account" "tiller" {
  automount_service_account_token = true
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.tiller.metadata.0.name}"
    api_group = ""
    namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "helm_release" "ingress" {
  name  = "ingress"
  chart = "stable/nginx-ingress"
}
