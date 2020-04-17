resource "aws_eks_fargate_profile" "fargate" {
  count = var.fargate_enabled ? 1 : 0

  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.environment_name}-fargate"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = aws_subnet.private.*.id

  selector {
    namespace = "fargate"
  }
}

resource "aws_iam_role" "fargate" {
  name = "${var.environment_name}-fargate"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}
