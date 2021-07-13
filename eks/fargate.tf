resource "aws_eks_fargate_profile" "fargate" {
  count = var.fargate_enabled ? 1 : 0
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.environment_name}-serverless"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = aws_subnet.private.*.id

  selector {
    namespace = var.fargate_namespace_selector_name
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
