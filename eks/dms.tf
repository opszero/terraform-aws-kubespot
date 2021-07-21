resource "aws_dms_replication_task" "analytics" {
  migration_type            = var.dms_cluster.migration_type
  replication_instance_arn  = aws_dms_replication_instance.analytics.replication_instance_arn
  replication_task_id       = "${var.environment_name}-analytics-replication-task"
  source_endpoint_arn       = aws_dms_endpoint.my-database-endpoint-source.endpoint_arn
  table_mappings            = file("${path.module}/replication_task_mappings.json")
  target_endpoint_arn = aws_dms_endpoint.analytics-endpoint-target.endpoint_arn
}

resource "aws_dms_replication_subnet_group" "analytics" {
  replication_subnet_group_description = "Replication subnet group for analytics"
  replication_subnet_group_id          = "my-database-analytics-replication-subnet-group"
  subnet_ids = [aws_subnet.private.*.id]
}

resource "aws_security_group" "analytics_replication_security_group" {
  name        = "${var.environment_name}-analytics-replication-security-group"
  description = "Allow application to reach DB"
  vpc_id      = aws_vpc.vpc.id
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_dms_replication_instance" "analytics" {
  allocated_storage          = var.dms_cluster.allocated_storage
  apply_immediately          = true
  auto_minor_version_upgrade = true
  engine_version             = var.dms_cluster.engine_version
  replication_instance_class  = var.dms_cluster.replication_instance_class
  replication_instance_id     = "${var.environment_name}-analytics-replication"
  replication_subnet_group_id = aws_dms_replication_subnet_group.analytics.id
  vpc_security_group_ids = [
    aws_security_group.analytics_replication_security_group.id,
    aws_security_group.analytics.id,
  ]
  depends_on = ["aws_iam_role.dms-vpc-role", "aws_iam_role_policy_attachment.dms-vpc-management-policy"]
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  name = "${var.environment_name}-dms-cloudwatch-logs-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "dms.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-policy" {
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_iam_role" "dms-vpc-role" {
  name = "${var.environment_name}-dms-vpc-role"
assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "dms.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dms-vpc-management-policy" {
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_dms_endpoint" "my-database-endpoint-source" {
  database_name = aws_db_instance.default.name
  endpoint_id   = "${var.environment_name}-endpoint-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  username      = var.sql_master_username # todo check if other user
  password      = var.sql_master_password # todo check if other user
  port          = aws_db_instance.default.port
  server_name   = aws_db_instance.default.address
  ssl_mode      = "none"
}


resource "aws_dms_endpoint" "analytics-endpoint-target" {
  database_name = aws_redshift_cluster.default.database_name
  endpoint_id   = "${var.environment_name}-endpoint-target"
  endpoint_type = "target"
  engine_name   = "redshift"
  username      = var.redshift_cluster.master_username
  password      = var.redis_num_nodes.master_password
  port          = aws_redshift_cluster.default.port
  server_name   = aws_redshift_cluster.default.dns_name
  ssl_mode      = "none"
}