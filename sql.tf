resource "aws_db_subnet_group" "default" {
  name       = var.environment_name
  subnet_ids = var.sql_subnet_group_include_public ? concat(aws_subnet.private.*.id, aws_subnet.public.*.id) : aws_subnet.private.*.id

  tags = local.tags
}

resource "aws_rds_cluster" "default" {
  count = var.sql_cluster_enabled ? 1 : 0

  cluster_identifier = var.environment_name
  engine             = var.sql_engine
  engine_mode        = var.sql_engine_mode
  engine_version     = var.sql_engine_version

  database_name               = var.sql_database_name
  master_username             = var.sql_master_username
  manage_master_user_password = true

  db_subnet_group_name            = aws_db_subnet_group.default.name
  vpc_security_group_ids          = [aws_security_group.node.id]
  db_cluster_parameter_group_name = var.sql_parameter_group_name == "" ? null : var.sql_parameter_group_name

  storage_type        = var.sql_storage_type
  storage_encrypted   = true
  deletion_protection = true // Don't Delete Ever! Except manually.

  backup_retention_period   = 20
  skip_final_snapshot       = var.sql_skip_final_snapshot
  final_snapshot_identifier = var.environment_name

  iam_database_authentication_enabled = var.sql_iam_auth_enabled

  tags = local.tags
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.sql_cluster_enabled ? var.sql_node_count : 0

  engine         = var.sql_engine
  engine_version = var.sql_engine_version

  cluster_identifier = aws_rds_cluster.default.0.id
  identifier         = "${var.environment_name}-${count.index}"

  instance_class = var.sql_instance_class

  monitoring_role_arn          = var.sql_cluster_monitoring_role_arn
  monitoring_interval          = var.sql_cluster_monitoring_interval
  performance_insights_enabled = var.sql_performance_insights_enabled

  db_subnet_group_name    = aws_db_subnet_group.default.name
  db_parameter_group_name = var.sql_parameter_group_name == "" ? null : var.sql_parameter_group_name

  tags = local.tags
}

resource "aws_db_instance" "default" {
  count = var.sql_instance_enabled ? 1 : 0

  identifier            = var.sql_identifier != "" ? var.sql_identifier : var.environment_name
  allocated_storage     = var.sql_instance_allocated_storage
  max_allocated_storage = var.sql_instance_max_allocated_storage

  storage_type   = var.sql_storage_type
  engine         = var.sql_instance_engine
  engine_version = var.sql_engine_version
  instance_class = var.sql_instance_class
  db_name        = var.sql_database_name
  username       = var.sql_master_username
  multi_az       = var.sql_rds_multi_az

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.node.id]
  parameter_group_name   = var.sql_parameter_group_name == "" ? null : var.sql_parameter_group_name

  storage_encrypted           = var.sql_encrypted
  allow_major_version_upgrade = true
  backup_retention_period     = 35
  deletion_protection         = true // Don't Delete Ever! Except manually.

  iam_database_authentication_enabled = var.sql_iam_auth_enabled

  tags = local.tags
}
