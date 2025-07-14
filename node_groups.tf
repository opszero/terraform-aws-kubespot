

module "eks_custom_ami" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks/modules/_user_data"

  # https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType
  for_each = {
    for k, v in var.node_groups : k => v if lookup(v, "node_disk_encrypted", false) == true
  }

  ami_type = each.value.ami_type

  cluster_name         = var.environment_name
  cluster_endpoint     = aws_eks_cluster.cluster.endpoint
  cluster_auth_base64  = aws_eks_cluster.cluster.certificate_authority[0].data
  cluster_service_cidr = aws_eks_cluster.cluster.kubernetes_network_config.0.service_ipv4_cidr

  enable_bootstrap_user_data = true

  bootstrap_extra_args = lookup(each.value, "ami_bootstrap_extra_args", "")
}

resource "aws_launch_template" "encrypted_launch_template" {
  for_each = { for k, v in var.node_groups : k => v if lookup(v, "node_disk_encrypted", false) }

  name_prefix = "${var.environment_name}-${each.key}"
  image_id    = data.aws_ssm_parameter.amis[each.value.ami_type].value
  user_data   = module.eks_custom_ami[each.key].user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 5
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = lookup(each.value, "root_node_disk_size", 20)
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  block_device_mappings {
    device_name = "/dev/xvdb"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = lookup(each.value, "node_disk_size", 20)
      volume_type           = "gp3"
      encrypted             = true
    }
  }
}

resource "aws_eks_node_group" "node_group" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.environment_name}-${each.key}"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = length(lookup(each.value, "subnet_ids", [])) == 0 ? (lookup(each.value, "nodes_in_public_subnet", true) ? aws_subnet.public.*.id : aws_subnet.private.*.id) : lookup(each.value, "subnet_ids", [])

  ami_type       = lookup(each.value, "node_disk_encrypted", false) ? "CUSTOM" : lookup(each.value, "ami_type", "BOTTLEROCKET_x86_64")
  instance_types = lookup(each.value, "instance_types", ["t2.micro"])
  disk_size      = lookup(each.value, "node_disk_encrypted", false) ? null : lookup(each.value, "node_disk_size", null)
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  labels         = lookup(each.value, "labels", {})

  dynamic "launch_template" {
    for_each = lookup(each.value, "node_disk_encrypted", false) ? [{
      id      = aws_launch_template.encrypted_launch_template[each.key].id
      version = aws_launch_template.encrypted_launch_template[each.key].latest_version
    }] : lookup(each.value, "launch_template", [])

    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version")
    }
  }

  scaling_config {
    desired_size = lookup(each.value, "node_desired_capacity", 1)
    max_size     = lookup(each.value, "nodes_max_size", 1)
    min_size     = lookup(each.value, "nodes_min_size", 1)
  }

  update_config {
    max_unavailable_percentage = lookup(each.value, "update_unavailable_percent", 50)
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value["key"]
      value  = lookup(taint.value, "value", null)
      effect = taint.value["effect"]
    }
  }

  tags = merge(
    local.tags,
    {
      "Name"                   = "${var.environment_name}-${each.key}"
      "karpenter.sh/discovery" = var.environment_name
    },
  )

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
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
  tags = local.tags
}
