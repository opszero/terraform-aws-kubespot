resource "aws_cloudwatch_metric_alarm" "nodes_green_cpu_threshold" {
  alarm_name                = "${var.environment_name}-cpu-threshold"
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


resource "aws_cloudwatch_log_group" "vpc" {
  name = var.environment_name
}
