resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = true

  tags = {
    "Name"                                      = var.cluster-name
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster-name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.cluster.name
}

resource "aws_security_group" "cluster" {
  name = "${var.cluster-name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cluster-name
  }
}

resource "aws_eks_cluster" "cluster" {
  name = var.cluster-name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]

    subnet_ids = flatten([
      aws_subnet.public.*.id,
      aws_subnet.private.*.id,
    ])
  }

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
        - "${var.cluster-name}"
      env:
        - name: AWS_PROFILE
          value: "${var.aws_profile}"
KUBECONFIG

}

output "kubeconfig" {
value = local.kubeconfig
}

resource "aws_iam_role" "node" {
name = "${var.cluster-name}-node"

assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
role = aws_iam_role.node.name
}

resource "aws_iam_instance_profile" "node" {
name = "${var.cluster-name}-node"
role = aws_iam_role.node.name
}

resource "aws_security_group" "node" {
name = "${var.cluster-name}-node"
description = "Security group for all nodes in the cluster"
vpc_id = aws_vpc.vpc.id

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
"Name" = "${var.cluster-name}-node"
"kubernetes.io/cluster/${var.cluster-name}" = "owned"
}
}

resource "aws_security_group_rule" "node-ssh" {
cidr_blocks = ["0.0.0.0/0"]
description = "Allow workstation to communicate with the cluster API Server"
from_port = 22
protocol = "-1"
security_group_id = aws_security_group.node.id
to_port = 22
type = "ingress"
}

resource "aws_security_group_rule" "node-ingress-self" {
description = "Allow node to communicate with each other"
from_port = 0
protocol = "-1"
security_group_id = aws_security_group.node.id
source_security_group_id = aws_security_group.node.id
to_port = 65535
type = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
from_port = 1025
protocol = "tcp"
security_group_id = aws_security_group.node.id
source_security_group_id = aws_security_group.cluster.id
to_port = 65535
type = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
description = "Allow pods to communicate with the cluster API Server"
from_port = 443
protocol = "tcp"
security_group_id = aws_security_group.cluster.id
source_security_group_id = aws_security_group.node.id
to_port = 443
type = "ingress"
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

/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA

}

resource "aws_launch_configuration" "nodes_blue" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ami.opszero_eks.id
  instance_type               = "t2.nano"
  name_prefix                 = "${var.cluster-name}-nodes-blue"
  security_groups             = [aws_security_group.node.id]
  user_data_base64            = base64encode(local.node-userdata)

  key_name = var.ec2_keypair

  root_block_device {
    volume_size = "100"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nodes_blue" {
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.nodes_blue.id
  max_size             = 1
  min_size             = 1
  name                 = "${var.cluster-name}-nodes-blue"

  vpc_zone_identifier = aws_subnet.private.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster-name}-nodes-blue"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster-name}"
      value               = "owned"
      propagate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "nodes_green" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ami.opszero_eks.id
  instance_type               = "m5.large"
  name_prefix                 = "${var.cluster-name}-nodes-green"
  security_groups             = [aws_security_group.node.id]
  user_data_base64            = base64encode(local.node-userdata)

  key_name = var.ec2_keypair

  root_block_device {
    volume_size = "100"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nodes_green" {
  desired_capacity     = 0
  launch_configuration = aws_launch_configuration.nodes_green.id
  max_size             = 0
  min_size             = 0
  name                 = "${var.cluster-name}-nodes-green"

  vpc_zone_identifier = aws_subnet.private.*.id

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster-name}-nodes-green"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster-name}"
      value               = "owned"
      propagate_at_launch = true
    },
  ]
}

data "aws_caller_identity" "current" {
}

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    %{for user in var.iam_users~}
    - userarn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}
      username: ${user}
      groups:
        - system:masters
    %{endfor~}
CONFIGMAPAWSAUTH

}

output "config-map-aws-auth" {
  value = local.config-map-aws-auth
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${var.environment-name}-eks"
}

kubernetes {
  host = "${aws.aws_eks_cluster.cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(aws.aws_eks_cluster.cluster.certificate_authority.0.data)}"
  token = "${data.aws_eks_cluster_auth.cluster.token}"
  load_config_file = false
}

resource "kubernetes_config_map" "config-map-aws-auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }

  data {
    config_map_aws_auth.yaml = local.config-map-aws-auth
  }
}
