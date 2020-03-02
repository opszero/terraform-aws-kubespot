resource "aws_eks_cluster" "cluster" {
  name     = var.environment_name
  role_arn = aws_iam_role.cluster.arn

  version = var.cluster_version

  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]

    subnet_ids = flatten([
      aws_subnet.public.*.id,
      aws_subnet.private.*.id,
    ])
  }

  enabled_cluster_log_types = var.cluster_logging

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]
}

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${var.environment_name}"
      env:
        - name: AWS_PROFILE
          value: "${var.aws_profile}"
KUBECONFIG

}

output "kubeconfig" {
  value = local.kubeconfig
}

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

resource "aws_launch_configuration" "nodes_blue" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ami.opszero_eks.id
  instance_type               = var.nodes_blue_instance_type
  name_prefix                 = "${var.environment_name}-nodes-blue"
  security_groups             = [aws_security_group.node.id]
  user_data_base64            = base64encode(local.node-userdata)

  key_name = var.ec2_keypair

  root_block_device {
    volume_size = var.nodes_blue_root_device_size
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nodes_blue" {
  desired_capacity      = var.nodes_blue_desired_capacity
  launch_configuration  = aws_launch_configuration.nodes_blue.id
  max_size              = var.nodes_blue_max_size
  min_size              = var.nodes_blue_min_size
  name                  = "${var.environment_name}-nodes-blue"
  max_instance_lifetime = var.nodes_blue_max_instance_lifetime

  vpc_zone_identifier = aws_subnet.private.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment_name}-nodes-blue"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.environment_name}"
      value               = "owned"
      propagate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "nodes_green" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ami.opszero_eks.id
  instance_type               = var.nodes_green_instance_type
  name_prefix                 = "${var.environment_name}-nodes-green"
  security_groups             = [aws_security_group.node.id]
  user_data_base64            = base64encode(local.node-userdata)

  key_name = var.ec2_keypair

  root_block_device {
    volume_size = var.nodes_green_root_device_size
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nodes_green" {
  desired_capacity      = var.nodes_green_desired_capacity
  launch_configuration  = aws_launch_configuration.nodes_green.id
  max_size              = var.nodes_green_max_size
  min_size              = var.nodes_green_min_size
  name                  = "${var.environment_name}-nodes-green"
  max_instance_lifetime = var.nodes_green_max_instance_lifetime

  vpc_zone_identifier = aws_subnet.private.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment_name}-nodes-green"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.environment_name}"
      value               = "owned"
      propagate_at_launch = true
    },
  ]
}

data "aws_caller_identity" "current" {
}

