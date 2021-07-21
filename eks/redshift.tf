resource "aws_redshift_cluster" "default" {
  cluster_identifier = "${var.environment_name}-redshift-cluster"
  database_name      = var.redshift_cluster.database_name
  master_username    = var.redshift_cluster.master_username
  master_password    = var.redshift_cluster.master_password
  node_type          = var.redshift_cluster.node_type
  cluster_type       = "single-node"
  number_of_nodes    = 1
}

resource "aws_redshift_parameter_group" "analytics" {
  name   = "${var.environment_name}-redshift-parameter-group"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true" # todo
  }
}

resource "aws_redshift_subnet_group" "analytics" {
  name = "${var.environment_name}-redshift-subnet-group"

  subnet_ids = [
    aws_subnet.public.*.id,
  ]
}

resource "aws_security_group" "analytics" {
  name   = "${var.environment_name}-redshift-security-group"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "analytics_self_ingress" {
  type      = "ingress"
  protocol  = "TCP"
  from_port = 0
  to_port   = 65535

  security_group_id        = aws_security_group.analytics.id
  source_security_group_id = aws_security_group.analytics.id
}

resource "aws_security_group_rule" "analytics_self_egress" {
  type      = "egress"
  protocol  = "TCP"
  from_port = 0
  to_port   = 65535

  security_group_id        = aws_security_group.analytics.id
  source_security_group_id = aws_security_group.analytics.id
}