resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = var.enable_ipv6


  tags = {
    "Name"                                          = var.environment_name
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "KubespotEnvironment"                           = var.environment_name
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

resource "aws_security_group" "cluster" {
  name        = "${var.environment_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                  = var.environment_name
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_security_group" "node" {
  name        = "${var.environment_name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                          = "${var.environment_name}-node"
    "kubernetes.io/cluster/${var.environment_name}" = "owned"
    "KubespotEnvironment"                           = var.environment_name
  }
}

output "node_security_group_id" {
  value = aws_security_group.node.id
}

resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "public_subnet" {
  description       = "Allow from public_subnet cidr"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = var.cidr_block_public_subnet
  type              = "ingress"
}

resource "aws_security_group_rule" "private_subnet" {
  description       = "Allow from public_subnet cidr"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = var.cidr_block_private_subnet
  type              = "ingress"
}
