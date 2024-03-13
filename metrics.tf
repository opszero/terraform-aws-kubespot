resource "aws_cloudwatch_log_group" "vpc" {
  name              = var.environment_name
  kms_key_id        = aws_kms_key.cloudwatch_log.arn
  retention_in_days = var.cloudwatch_retention_in_days
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_nodes_cpu_threshold" {
  for_each = var.asg_nodes

  alarm_name                = "${var.environment_name}-nodes-${each.key}-cpu-threshold"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_nodes[each.key].name
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu_database" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-cpu-database"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_disk_database" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-disk-database"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "VolumeReadIOPs"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS disk utilization"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_disk_database" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-free-disk-database"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "AuroraVolumeBytesLeftTotal"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_disk_database2" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-free-disk-database2"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_disk_database3" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-free-disk-database3"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeLocalStorage"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}



resource "aws_cloudwatch_metric_alarm" "database_free_disk_database4" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-free-disk-database4"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_disk_database5" {
  count                     = var.sql_instance_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-free-disk-database5"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeLocalStorage"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBInstanceIdentifier = aws_rds_instance.default[0].identifier
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_io_postgres" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-io-postgres"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "DiskQueueDepth"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "database_io_mysql" {
  count                     = var.sql_cluster_enabled ? 1 : 0
  alarm_name                = "${var.environment_name}-io-mysql"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "VolumeReadIOPs"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.default[0].cluster_identifier
  }
  tags = local.tags
}

