resource "aws_eks_node_group" "node_group" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.environment_name}-${each.key}"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = length(lookup(each.value, "subnet_ids", [])) == 0 ? (lookup(each.value, "nodes_in_public_subnet", true) ? aws_subnet.public.*.id : aws_subnet.private.*.id) : lookup(each.value, "subnet_ids", [])

  ami_type       = lookup(each.value, "ami_type", "BOTTLEROCKET_x86_64")
  instance_types = lookup(each.value, "instance_types", ["t2.micro"])
  disk_size      = lookup(each.value, "node_disk_size", 20)
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  scaling_config {
    desired_size = lookup(each.value, "node_desired_capacity", 1)
    max_size     = lookup(each.value, "nodes_max_size", 1)
    min_size     = lookup(each.value, "nodes_min_size", 1)
  }

  update_config {
    max_unavailable_percentage = lookup(each.value, "update_unavailable_percent", 50)
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
