provider "helm" {
  install_tiller  = true
//  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
  //namespace = "kube-system"
  //tiller_image = "gcr.io/kubernetes-helm/tiller:v2.14.1"


  kubernetes {
    host                   = "${azurerm_kubernetes_cluster.cluster.kube_config.0.host}"
    username               = "${azurerm_kubernetes_cluster.cluster.kube_config.0.username}"
    password               = "${azurerm_kubernetes_cluster.cluster.kube_config.0.password}"
    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)}"
  }
}

# resource "kubernetes_service_account" "tiller" {
#   automount_service_account_token = true

#   metadata {
#     name      = "terraform-tiller"
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_cluster_role_binding" "tiller" {
#   metadata {
#     name = "terraform-tiller"
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
#     name      = "terraform-tiller"
#     namespace = "kube-system"
#   }
# }

# resource "helm_release" "ingress" {
#   name  = "ingress"
#   chart = "stable/nginx-ingress"
# }
