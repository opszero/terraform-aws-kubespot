resource "aws_flow_log" "vpc" {
  count = var.vpc_flow_logs_enabled ? 1 : 0

  iam_role_arn    = aws_iam_role.vpc.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_iam_role" "vpc" {
  name = var.environment_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_iam_role_policy" "vpc" {
  name = var.environment_name
  role = aws_iam_role.vpc.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
