resource "aws_cloudwatch_log_group" "vpc" {
  name = var.environment_name
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
    auto_scaling_group_name = aws_autoscaling_group.nodes_green.name
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
    auto_scaling_group_name = aws_autoscaling_group.nodes_blue.name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu_database" {
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
}

resource "aws_cloudwatch_metric_alarm" "database_disk_database" {
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
}

resource "aws_cloudwatch_metric_alarm" "database_free_disk_database" {
  alarm_name                = "${var.environment_name}-free-disk-database"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "AuroraVolumeBytesLeftTotal"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors RDS free disk space"
  insufficient_data_actions = []
}
