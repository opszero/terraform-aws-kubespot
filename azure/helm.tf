provider "helm" {
  install_tiller  = false
  //  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
  //namespace = "kube-system"
  kubernetes {
    host                   = "${azurerm_kubernetes_cluster.cluster.kube_config.0.host}"
    username               = "${azurerm_kubernetes_cluster.cluster.kube_config.0.username}"
    password               = "${azurerm_kubernetes_cluster.cluster.kube_config.0.password}"
    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)}"
    load_config_file       = false
  }
}


resource "null_resource" "helm_init" {
  provisioner "local-exec" {
    command = "helm init --wait --replicas 1 --tiller-namespace kube-system --service-account=${kubernetes_service_account.tiller.metadata.0.name}"
  }

  depends_on = ["kubernetes_cluster_role_binding.tiller"]
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
    name      = "terraform-tiller"
    namespace = "kube-system"
  }
}

# resource "helm_release" "ingress" {
#   name  = "ingress"
#   chart = "stable/nginx-ingress"
#  depends_on = ["null_resource.helm_init"]

# }
