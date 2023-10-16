################################################################################
# Launch template
################################################################################

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = try(aws_launch_template.this[0].id, "")
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = try(aws_launch_template.this[0].arn, "")
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = try(aws_launch_template.this[0].latest_version, "")
}

################################################################################
# Node Group
################################################################################

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = try(aws_eks_node_group.this[0].arn, "")
}

output "node_group_id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon (`:`)"
  value       = try(aws_eks_node_group.this[0].id, "")
}

output "node_group_resources" {
  description = "List of objects containing information about underlying resources"
  value       = try(aws_eks_node_group.this[0].resources, "")
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = try(aws_eks_node_group.this[0].arn, "")
}
