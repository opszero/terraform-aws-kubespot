resource "helm_release" "csi_secrets_store" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"

  namespace        = "kube-system"
  create_namespace = false
}

data "http" "csi_secrets_store_aws_provider" {
  url = "https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
}

resource "null_resource" "csi_secrets_store_aws_provider" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  triggers = {
    name       = helm_release.csi_secrets_store.name
    namespace  = helm_release.csi_secrets_store.namespace
    repository = helm_release.csi_secrets_store.repository
  }

  depends_on = [helm_release.csi_secrets_store]

  provisioner "local-exec" {
    command = "kubectl apply -f -<<EOF\n${data.http.csi_secrets_store_aws_provider.body}\nEOF"
  }
}