provider "helm" {
  kubernetes {
    host                   = "${google_container_cluster.cluster.endpoint}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)}"
    client_certificate     = "${base64decode(google_container_cluster.cluster.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.cluster.master_auth.0.client_key)}"
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

# resource "kubernetes_cluster_role_binding" "tiller" {
#   metadata {
#     name = "tiller"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "${kubernetes_service_account.tiller.metadata.0.name}"
#     api_group = ""
#     namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "tiller"
#     namespace = "kube-system"
#   }
# }
