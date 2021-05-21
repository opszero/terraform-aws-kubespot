resource "aws_cloudwatch_log_group" "vpc" {
  name = var.environment_name
}

resource "aws_cloudwatch_metric_alarm" "bastion_cpu_threshold" {
  count = var.bastion_enabled ? 1 : 0

  alarm_name                = "${var.environment_name}-bastion-cpu-threshold"
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
    InstanceId = aws_instance.bastion[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "nodes_green_cpu_threshold" {
  alarm_name                = "${var.environment_name}-nodes-green-cpu-threshold"
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
    AutoScalingGroupName = aws_autoscaling_group.nodes_green.name
  }
}

resource "aws_cloudwatch_metric_alarm" "nodes_blue_cpu_threshold" {
  alarm_name                = "${var.environment_name}-nodes-blue-cpu-threshold"
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
    AutoScalingGroupName = aws_autoscaling_group.nodes_blue.name
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
}
