resource "aws_guardduty_detector" "detector" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    eks_logs {
      enable = var.eks_guardduty_enabled
    }
  }
}
