module "eks_managed_node_group" {
  source = "./node_group"

  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  cluster_version = var.cluster_version
  vpc_security_group_ids = compact(
    concat(
      aws_eks_cluster.cluster.vpc_config.0.cluster_security_group_id
      #var.nodes_additional_security_group_ids

    )
  )
  # EKS Managed Node Group
  name        = try(each.value.name, each.key)
  environment = var.environment_name
  subnet_ids  = length(lookup(each.value, "subnet_ids", [])) == 0 ? (lookup(each.value, "nodes_in_public_subnet", true) ? aws_subnet.public.*.id : aws_subnet.private.*.id) : lookup(each.value, "subnet_ids", [])

  min_size     = try(each.value.min_size, var.node_group_defaults.min_size, 1)
  max_size     = try(each.value.max_size, var.node_group_defaults.max_size, 1)
  desired_size = try(each.value.desired_size, var.node_group_defaults.desired_size, 1)

  ami_id              = try(each.value.ami_id, var.node_group_defaults.ami_id, "BOTTLEROCKET_x86_64")
  ami_type            = try(each.value.ami_type, var.node_group_defaults.ami_type, null)
  ami_release_version = try(each.value.ami_release_version, var.node_group_defaults.ami_release_version, null)

  capacity_type        = try(each.value.capacity_type, var.node_group_defaults.capacity_type, null)
  disk_size            = try(each.value.disk_size, var.node_group_defaults.disk_size, 20)
  force_update_version = try(each.value.force_update_version, var.node_group_defaults.force_update_version, null)
  instance_types       = try(each.value.instance_types, var.node_group_defaults.instance_types, ["t2.micro"])
  labels               = try(each.value.labels, var.node_group_defaults.labels, null)

  remote_access = try(each.value.remote_access, var.node_group_defaults.remote_access, {})
  taints        = try(each.value.taints, var.node_group_defaults.taints, {})
  update_config = try(each.value.update_config, var.node_group_defaults.update_config, {
    max_unavailable_percentage = lookup(each.value, "update_unavailable_percent", 50)
    }
  )
  timeouts = try(each.value.timeouts, var.node_group_defaults.timeouts, {})

  #------------ASG-Schedule--------------------------------------------------
  create_schedule = try(each.value.create_schedule, var.node_group_defaults.create_schedule, true)
  schedules       = try(each.value.schedules, var.node_group_defaults.schedules, null) #var.schedules)

  # Launch Template
  launch_template_description = try(each.value.launch_template_description, var.node_group_defaults.launch_template_description, "Custom launch template for ${try(each.value.name, each.key)} EKS managed node group")
  launch_template_tags        = try(each.value.launch_template_tags, var.node_group_defaults.launch_template_tags, {})

  ebs_optimized = try(each.value.ebs_optimized, var.node_group_defaults.ebs_optimized, null)
  key_name      = try(each.value.key_name, var.node_group_defaults.key_name, null)
  kms_key_id    = try(each.value.kms_key_id, var.node_group_defaults.ebs_optimized, null)

  launch_template_default_version        = try(each.value.launch_template_default_version, var.node_group_defaults.launch_template_default_version, null)
  update_launch_template_default_version = try(each.value.update_launch_template_default_version, var.node_group_defaults.update_launch_template_default_version, true)
  disable_api_termination                = try(each.value.disable_api_termination, var.node_group_defaults.disable_api_termination, null)
  kernel_id                              = try(each.value.kernel_id, var.node_group_defaults.kernel_id, null)
  ram_disk_id                            = try(each.value.ram_disk_id, var.node_group_defaults.ram_disk_id, null)

  block_device_mappings              = try(each.value.block_device_mappings, var.node_group_defaults.block_device_mappings, {})
  capacity_reservation_specification = try(each.value.capacity_reservation_specification, var.node_group_defaults.capacity_reservation_specification, null)
  cpu_options                        = try(each.value.cpu_options, var.node_group_defaults.cpu_options, null)
  credit_specification               = try(each.value.credit_specification, var.node_group_defaults.credit_specification, null)
  elastic_gpu_specifications         = try(each.value.elastic_gpu_specifications, var.node_group_defaults.elastic_gpu_specifications, null)
  elastic_inference_accelerator      = try(each.value.elastic_inference_accelerator, var.node_group_defaults.elastic_inference_accelerator, null)
  enclave_options                    = try(each.value.enclave_options, var.node_group_defaults.enclave_options, null)
  license_specifications             = try(each.value.license_specifications, var.node_group_defaults.license_specifications, null)
  metadata_options                   = try(each.value.metadata_options, var.node_group_defaults.metadata_options, local.metadata_options)
  enable_monitoring                  = try(each.value.enable_monitoring, var.node_group_defaults.enable_monitoring, true)
  network_interfaces                 = try(each.value.network_interfaces, var.node_group_defaults.network_interfaces, [])
  placement                          = try(each.value.placement, var.node_group_defaults.placement, null)

  # IAM role
  iam_role_arn = try(each.value.iam_role_arn, var.node_group_defaults.iam_role_arn, null)

  tags = merge(var.tags,
    try(each.value.tags, {
      "karpenter.sh/discovery" = var.environment_name
      },
  var.node_group_defaults.tags, {}))
}




resource "aws_cloudwatch_metric_alarm" "node_group_cpu_threshold" {
  # One Alarm Per One Node Group
  for_each = aws_eks_node_group.node_group

  alarm_name                = "${var.environment_name}-${each.value.node_group_name}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.node_group_cpu_threshold
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = join("", flatten(each.value.resources[*].autoscaling_groups.*.name))
  }
  tags = var.tags
}
