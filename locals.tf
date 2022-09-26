locals {
  alb_name = "aws-load-balancer-controller"
  arn_env  = var.govcloud ? "aws-us-gov" : "aws"

  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
}
