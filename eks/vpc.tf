resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = true

  tags = {
    "Name"                                      = var.cluster-name
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster-name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cluster-name
  }
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
