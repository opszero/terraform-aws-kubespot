locals {
  alb_name   = "aws-load-balancer-controller"
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
