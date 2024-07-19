# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  node-userdata = <<USERDATA
#!/bin/bash -xe
set -o xtrace

/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority[0].data}' '${var.environment_name}'
USERDATA
}





resource "aws_launch_template" "asg_encrypted_launch_template" {
  for_each = var.asg_nodes != null ? { for k, v in var.asg_nodes : k => v if lookup(v, "node_disk_encrypted", false) == true } : {}

  name_prefix = "${var.environment_name}-${each.key}"
  image_id    = data.aws_ssm_parameter.eks_ami.value
  user_data   = base64encode(local.node-userdata)

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = 2
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  block_device_mappings {
    device_name = "/dev/xvdb"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = lookup(each.value, "node_disk_size", 32)
      volume_type           = "gp3"
      encrypted             = true
    }
  }
}

resource "aws_autoscaling_group" "asg_nodes" {
  for_each = var.asg_nodes

  desired_capacity      = each.value.nodes_desired_capacity
  launch_template {
    id    = aws_launch_template.asg_encrypted_launch_template[each.key].id
    version = aws_launch_template.asg_encrypted_launch_template[each.key].latest_version
  }
  max_size              = each.value.nodes_max_size
  min_size              = each.value.nodes_min_size
  name                  = "${var.environment_name}-nodes-${each.key}"

  vpc_zone_identifier = aws_subnet.public.*.id

  enabled_metrics = lookup(each.value, "node_enabled_metrics", [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ])

  tag {
    key                 = "Name"
    value               = "${var.environment_name}-nodes-${each.key}"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.environment_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.environment_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "TRUE"
    propagate_at_launch = true
  }
  tag {
    key                 = "KubespotEnvironment"
    value               = var.environment_name
    propagate_at_launch = true
  }
  tag {
    key                 = "karpenter.sh/discovery"
    value               = var.environment_name
    propagate_at_launch = true
  }
}
