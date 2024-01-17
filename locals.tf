locals {
  alb_name   = "aws-load-balancer-controller"
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  # https://github.com/aws-samples/amazon-cloudwatch-container-insights/releases
  eks_pod_logs_cloudwatch_fluent_bit_version = "1.3.19"

  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
