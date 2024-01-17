resource "aws_iam_role" "node" {
  name = "${var.environment_name}-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_role_policies" {
  count      = length(var.node_role_policies)
  policy_arn = var.node_role_policies[count.index]
  role       = aws_iam_role.node.name
}


resource "aws_iam_policy" "eks_pod_logs_to_cloudwatch" {
  count       = var.eks_pod_logs_cloudwatch ? 1 : 0
  name        = "nodeEksPodLogsToCloudwatch"
  description = "Used by fluentbit agent to send eks pods logs to cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
      ],
      "Resource": [*]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "node_eks_pod_logs_to_cloudwatch" {
  count      = var.eks_pod_logs_cloudwatch ? 1 : 0
  policy_arn = aws_iam_policy.eks_pod_logs_to_cloudwatch.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.environment_name}-node"
  role = aws_iam_role.node.name
  tags = local.tags
}
