resource "helm_release" "csi-secrets-store" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"

  namespace        = "kube-system"
  create_namespace = false


}

data "http" "secrets_store_csi_driver_aws" {
  url = "https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
}

resource "null_resource" "helm_test_csi_secrets_store" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  triggers = {
    name       = helm_release.csi-secrets-store.name
    namespace  = helm_release.csi-secrets-store.namespace
    repository = helm_release.csi-secrets-store.repository
  }

  depends_on = [helm_release.csi-secrets-store]

  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.http.secrets_store_csi_driver.body}\nEOF"
  }
}