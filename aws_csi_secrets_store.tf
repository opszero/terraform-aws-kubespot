resource "helm_release" "csi_secrets_store" {
  count = var.csi_secrets_store_enabled ? 1 : 0

  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.csi_secrets_store_version
  namespace        = "kube-system"
  create_namespace = false
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
  name        = "secrets-access-policy"
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
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:testing-KBgXuY"
        ]
      }
    ]
  })
}


data "aws_iam_policy_document" "trust_relationship" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [replace(aws_eks_cluster.cluster.identity[0].oidc.issuer, "https://", "")]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc.issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "secrets_manager_role" {
  name               = "secrets_manager_role"
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
}

# Step 3: Attach Policy to Role
resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}
