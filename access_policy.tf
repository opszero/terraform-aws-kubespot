resource "aws_eks_access_policy_association" "policies" {
  count         = length(var.access_policies)
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = lookup(var.access_policies[count.index], "principal_arn")
  policy_arn    = lookup(var.access_policies[count.index], "policy_arn")
  access_scope  = lookup(var.access_policies[count.index], "access_scope", { type = "cluster" })
}
