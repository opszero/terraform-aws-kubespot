resource "aws_eks_node_group" "workers" {

  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.environment_name}-workers-${each.key}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids = flatten([
    aws_subnet.private.*.id,
  ])

  disk_size      = lookup(each.value, "node_disk_size", 20)
  instance_types = lookup(each.value, "instance_type", "t2.micro")
  scaling_config {
    desired_size = lookup(each.value, "node_desired_capacity", 1)
    max_size     = lookup(each.value, "nodes_max_size", 1)
    min_size     = lookup(each.value, "nodes_min_size", 1)
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

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
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}