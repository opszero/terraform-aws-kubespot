## currently terraform doesn't support eks audit logs 

/*resource "aws_guardduty_detector" "detector" {
  enable = true

  datasources {
    eks_logs {
      enable = var.eks_guardduty_enabled
    }
  }
}*/
