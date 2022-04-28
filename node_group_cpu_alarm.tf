resource "aws_cloudwatch_metric_alarm" "node_group_cpu_threshold" {
  # One Alarm Per One Node Group
  for_each = aws_eks_node_group.node_group

  alarm_name                = "${var.environment_name}-${each.value.node_group_name}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.node_group_cpu_threshold
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = jsonencode(flatten(each.value.resources[*].autoscaling_groups.*.name))
  }
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
