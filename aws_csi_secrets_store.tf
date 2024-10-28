resource "helm_release" "csi_secrets_store" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.csi_secrets_store_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }
}

data "http" "csi_secrets_store_aws_provider" {
  url = "https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
}

resource "null_resource" "csi_secrets_store_aws_provider" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  triggers = {
    name       = helm_release.csi_secrets_store[0].name
    namespace  = helm_release.csi_secrets_store[0].namespace
    repository = helm_release.csi_secrets_store[0].repository
  }

  depends_on = [helm_release.csi_secrets_store]

  provisioner "local-exec" {
    command = "kubectl apply -f ${data.http.csi_secrets_store_aws_provider.url}"
  }
}

