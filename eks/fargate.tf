resource "aws_eks_fargate_profile" "fargate" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.environment_name}-fargate"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = aws_subnet.private.*.id

  selector {
    namespace = "fargate"
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
