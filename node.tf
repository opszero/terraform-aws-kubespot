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

resource "aws_launch_configuration" "asg_nodes" {
  for_each = var.asg_nodes

  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ssm_parameter.eks_ami.value
  instance_type               = each.value.instance_type
  name_prefix                 = "${var.environment_name}-nodes-${each.key}"
  spot_price                  = each.value.spot_price
  security_groups             = [
    aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id,
    aws_security_group.node.id
  ]
  user_data_base64            = base64encode(local.node-userdata)
  associate_public_ip_address = each.value.nodes_in_public_subnet

  root_block_device {
    volume_size = each.value.node_disk_size
    encrypted   = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_nodes" {
  for_each = var.asg_nodes

  desired_capacity      = each.value.nodes_desired_capacity
  launch_configuration  = aws_launch_configuration.asg_nodes[each.key].id
  max_size              = each.value.nodes_max_size
  min_size              = each.value.nodes_min_size
  name                  = "${var.environment_name}-nodes-${each.key}"
  max_instance_lifetime = each.value.max_instance_lifetime

  vpc_zone_identifier = length(each.value.subnet_ids) == 0 ? (each.value.nodes_in_public_subnet ? aws_subnet.public.*.id : aws_subnet.private.*.id) : each.value.subnet_ids

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
