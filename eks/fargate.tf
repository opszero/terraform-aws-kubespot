resource "aws_eks_fargate_profile" "fargate" {
  for_each               = var.fargate_selector
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.environment_name}-${each.key}"
  pod_execution_role_arn = lookup(each.value, "role_arn", aws_iam_role.fargate.arn)
  subnet_ids             = aws_subnet.private.*.id

  selector {
    namespace = each.key
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
