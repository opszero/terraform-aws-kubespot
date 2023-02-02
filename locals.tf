locals {
  alb_name   = "aws-load-balancer-controller"
  partition  = var.govcloud ? "aws-us-gov" : "aws"
  account_id = data.aws_caller_identity.current.account_id

  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
}
