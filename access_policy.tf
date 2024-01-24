resource "aws_eks_access_policy_association" "policies" {
  count         = length(var.access_policies)
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = lookup(var.access_policies[count.index], "principal_arn")
  policy_arn    = lookup(var.access_policies[count.index], "policy_arn")
  dynamic "access_scope" {
    for_each = var.access_policies[count.index].access_scope
    content {
      type       = lookup(access_scope, "type", "cluster")
      namespaces = lookup(access_scope, "namespaces", ["default"])
    }
  }
}
