locals {
  alb_name   = "aws-load-balancer-controller"
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  aws_policy_prefix             = format("arn:%s:iam::aws:policy", join("", data.aws_partition.current.*.partition))

}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
