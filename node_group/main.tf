data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

#Module      : label
#Description : Terraform module to create consistent naming for multiple names.
module "labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.0"

  name        = var.name
  repository  = var.repository
  environment = var.environment
  managedby   = var.managedby
  extra_tags  = var.tags
  attributes  = compact(concat(var.attributes, ["nodes"]))
  label_order = var.label_order
}


################################################################################
# Launch template
################################################################################



resource "aws_launch_template" "this" {
  count       = var.enabled ? 1 : 0
  name        = module.labels.id
  description = var.launch_template_description

  ebs_optimized = var.ebs_optimized
  image_id      = var.ami_id
  # # Set on node group instead
  # instance_type = var.launch_template_instance_type
  key_name               = var.key_name
  user_data              = var.before_cluster_joining_userdata
  vpc_security_group_ids = var.vpc_security_group_ids

  disable_api_termination = var.disable_api_termination
  kernel_id               = var.kernel_id
  ram_disk_id             = var.ram_disk_id

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = flatten([lookup(block_device_mappings.value, "ebs", [])])
        content {
          delete_on_termination = true
          encrypted             = true
          kms_key_id            = var.kms_key_id
          iops                  = lookup(ebs.value, "iops", null)
          throughput            = lookup(ebs.value, "throughput", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = lookup(capacity_reservation_specification.value, "capacity_reservation_preference", null)

      dynamic "capacity_reservation_target" {
        for_each = lookup(capacity_reservation_specification.value, "capacity_reservation_target", [])
        content {
          capacity_reservation_id = lookup(capacity_reservation_target.value, "capacity_reservation_id", null)
        }
      }
    }
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []
    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []
    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "elastic_gpu_specifications" {
    for_each = var.elastic_gpu_specifications != null ? [var.elastic_gpu_specifications] : []
    content {
      type = elastic_gpu_specifications.value.type
    }
  }

  dynamic "elastic_inference_accelerator" {
    for_each = var.elastic_inference_accelerator != null ? [var.elastic_inference_accelerator] : []
    content {
      type = elastic_inference_accelerator.value.type
    }
  }

  dynamic "enclave_options" {
    for_each = var.enclave_options != null ? [var.enclave_options] : []
    content {
      enabled = enclave_options.value.enabled
    }
  }


  dynamic "license_specification" {
    for_each = var.license_specifications != null ? [var.license_specifications] : []
    content {
      license_configuration_arn = license_specifications.value.license_configuration_arn
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
      http_protocol_ipv6          = lookup(metadata_options.value, "http_protocol_ipv6", null)
      instance_metadata_tags      = lookup(metadata_options.value, "instance_metadata_tags", null)
    }
  }

  dynamic "monitoring" {
    for_each = var.enable_monitoring != null ? [1] : []
    content {
      enabled = var.enable_monitoring
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_carrier_ip_address = lookup(network_interfaces.value, "associate_carrier_ip_address", null)
      associate_public_ip_address  = lookup(network_interfaces.value, "associate_public_ip_address", null)
      delete_on_termination        = lookup(network_interfaces.value, "delete_on_termination", null)
      description                  = lookup(network_interfaces.value, "description", null)
      device_index                 = lookup(network_interfaces.value, "device_index", null)
      ipv4_addresses               = lookup(network_interfaces.value, "ipv4_addresses", null) != null ? network_interfaces.value.ipv4_addresses : []
      ipv4_address_count           = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv6_addresses               = lookup(network_interfaces.value, "ipv6_addresses", null) != null ? network_interfaces.value.ipv6_addresses : []
      ipv6_address_count           = lookup(network_interfaces.value, "ipv6_address_count", null)
      network_interface_id         = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address           = lookup(network_interfaces.value, "private_ip_address", null)
      security_groups              = lookup(network_interfaces.value, "security_groups", null) != null ? network_interfaces.value.security_groups : []
      # Set on EKS managed node group, will fail if set here
      # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-basics
      # subnet_id                    = lookup(network_interfaces.value, "subnet_id", null)
    }
  }

  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []
    content {
      affinity          = lookup(placement.value, "affinity", null)
      availability_zone = lookup(placement.value, "availability_zone", null)
      group_name        = lookup(placement.value, "group_name", null)
      host_id           = lookup(placement.value, "host_id", null)
      spread_domain     = lookup(placement.value, "spread_domain", null)
      tenancy           = lookup(placement.value, "tenancy", null)
      partition_number  = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume", "network-interface"])
    content {
      resource_type = tag_specifications.key
      tags = merge(
        module.labels.tags,
      { Name = module.labels.id })
    }
  }


  lifecycle {
    create_before_destroy = true
  }

  tags = module.labels.tags
}

################################################################################
# Node Group
################################################################################

resource "aws_eks_node_group" "this" {
  count = var.enabled ? 1 : 0

  # Required
  cluster_name  = var.cluster_name
  node_role_arn = var.iam_role_arn
  subnet_ids    = var.subnet_ids

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  # Optional
  node_group_name = module.labels.id

  # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
  ami_type        = var.ami_id != "" ? null : var.ami_type
  release_version = var.ami_id != "" ? null : var.ami_release_version
  version         = var.ami_id != "" ? null : var.cluster_version

  capacity_type        = var.capacity_type
  disk_size            = var.disk_size
  force_update_version = var.force_update_version
  instance_types       = var.instance_types
  labels               = var.labels

  dynamic "launch_template" {
    for_each = var.enabled ? [1] : []
    content {
      name    = try(aws_launch_template.this[0].name)
      version = try(aws_launch_template.this[0].latest_version)
    }
  }

  dynamic "remote_access" {
    for_each = length(var.remote_access) > 0 ? [var.remote_access] : []
    content {
      ec2_ssh_key               = try(remote_access.value.ec2_ssh_key, null)
      source_security_group_ids = try(remote_access.value.source_security_group_ids, [])
    }
  }

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value")
      effect = taint.value.effect
    }
  }

  dynamic "update_config" {
    for_each = length(var.update_config) > 0 ? [var.update_config] : []
    content {
      max_unavailable_percentage = try(update_config.value.max_unavailable_percentage, null)
      max_unavailable            = try(update_config.value.max_unavailable, null)
    }
  }

  timeouts {
    create = lookup(var.timeouts, "create", null)
    update = lookup(var.timeouts, "update", null)
    delete = lookup(var.timeouts, "delete", null)
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }

  tags = module.labels.tags
}

#-----------------------------------------------ASG-Schedule----------------------------------------------------------------

resource "aws_autoscaling_schedule" "this" {
  for_each = var.enabled && var.create_schedule ? var.schedules : {}

  scheduled_action_name  = each.key
  autoscaling_group_name = aws_eks_node_group.this[0].resources[0].autoscaling_groups[0].name

  min_size         = lookup(each.value, "min_size", null)
  max_size         = lookup(each.value, "max_size", null)
  desired_capacity = lookup(each.value, "desired_size", null)
  start_time       = lookup(each.value, "start_time", null)
  end_time         = lookup(each.value, "end_time", null)
  time_zone        = lookup(each.value, "time_zone", null)

  # [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]
  # Cron examples: https://crontab.guru/examples.html
  recurrence = lookup(each.value, "recurrence", null)
}