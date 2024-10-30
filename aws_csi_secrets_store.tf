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



resource "aws_iam_policy" "secrets_policy" {
  count = var.csi_secrets_store_enabled ? 1 : 0
  name        = "csi-secrets-access-policy-${var.environment_name}"
  description = "Policy for accessing secrets in AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "trust_relationship" {
  # Create a statement for each namespace
  dynamic "statement" {
    for_each = var.csi_enabled_namespaces

    content {
      effect = "Allow"

      principals {
        type        = "Federated"
        identifiers = [local.oidc_provider_arn]
      }

      actions = ["sts:AssumeRoleWithWebIdentity"]

      condition {
        test     = "StringEquals"
        variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud"
        values   = ["sts.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
        values   = ["system:serviceaccount:${statement.value}:csi-secrets-service-account"]
      }
    }
  }
}

resource "aws_iam_role" "secrets_manager_role" {
  count = var.csi_secrets_store_enabled ? 1 : 0
  name               = "shared_secrets_manager_role"
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
}

resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = join("",aws_iam_role.secrets_manager_role.*.name)
  policy_arn = join ("", aws_iam_policy.secrets_policy.*.arn)
}


resource "kubernetes_service_account" "main" {
  for_each = toset(var.csi_enabled_namespaces) 

  metadata {
    name      = "csi-secrets-service-account"
    namespace = each.key
    annotations = {
      "eks.amazonaws.com/role-arn" = join("",aws_iam_role.secrets_manager_role.*.arn)
    }
  }
}
