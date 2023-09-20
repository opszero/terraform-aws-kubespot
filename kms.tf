resource "aws_kms_key" "cluster" {
  description             = "EKS Cluster ${var.environment_name} Encryption Config KMS Key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = var.cluster_kms_policy
  tags                    =  local.tags
}


resource "aws_kms_key" "cloudwatch_log" {
  description             = "CloudWatch log group ${var.environment_name} Encryption Config KMS Key"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.cloudwatch.json
  tags                    =  local.tags
}

data "aws_iam_policy_document" "cloudwatch" {
  policy_id = "key-policy-cloudwatch"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          join("", data.aws_partition.current.*.partition),
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        format(
          "logs.%s.amazonaws.com",
          data.aws_region.current.name
        )
      ]
    }
    resources = ["*"]
  }
}
