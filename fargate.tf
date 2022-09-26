resource "aws_eks_fargate_profile" "fargate" {
  for_each               = var.fargate_selector
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "${var.environment_name}-${each.key}"
  pod_execution_role_arn = lookup(each.value, "role_arn", aws_iam_role.fargate.arn)
  subnet_ids             = lookup(each.value, "subnet_ids", aws_subnet.private.*.id)

  selector {
    namespace = each.key
  }
  tags = local.tags
}

resource "aws_iam_role" "fargate" {
  name = "${var.environment_name}-fargate"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
        ]
      }
    }]
    Version = "2012-10-17"
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fargate-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:${local.arn_env}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}
